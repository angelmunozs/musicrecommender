/*
 * Based on original code from Sanford Ryza, Uri Laserson, Sean Owen and Joshua Wills
 * Modified by Daniel Revilla, Alberto Escorial and Ángel Muñoz for SIBD
 */

// Import Scala libraries
import scala.collection.Map
import scala.collection.mutable.ArrayBuffer
import scala.util.Random
import org.apache.spark.broadcast.Broadcast
import org.apache.spark.ml.recommendation.{ALS, ALSModel}
import org.apache.spark.sql.{DataFrame, Dataset, SparkSession}
import org.apache.spark.sql.functions._

object RunRecommender {

  // Import and declare utils
  val log = new CustomLogger()

  // Parameters:
  // - args(0): Route to Spark checkpoint directory.
  // - args(1): Route to data files.
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder().getOrCreate()

    try {
      // Parameters
      val checkpointDir = args(0) + "/tmp/"
      val dataHome = args(0) + "/data/"
      val rawUserArtistData = spark.read.textFile(dataHome + "user_artist_data.txt")
      val rawArtistData = spark.read.textFile(dataHome + "artist_data.txt")
      val rawArtistAlias = spark.read.textFile(dataHome + "artist_alias.txt")

      // Optional, but may help avoid errors due to long lineage
      spark.sparkContext.setCheckpointDir(checkpointDir)

      // Create new recommender
      val runRecommender = new RunRecommender(spark)

      // Prompt for user ID and no. recommendations via the command line
      askAction(rawUserArtistData, rawArtistData, rawArtistAlias, runRecommender)
    }
    catch {
      case e: Exception =>
        e.printStackTrace()
        log.error("Wrong first parameter: data home.")
        System.exit(1)
    }
  }

  def askAction(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String],
    runRecommender: RunRecommender
  ): Unit = {

    println("List of actions:\n"+
      " [1] Make recommendations\n"+
      " [2] Show most listened\n"+
      " [3] Show statistics\n" +
      " [4] Search artist\n"+
      " [5] Evaluate recommendations\n"+
      " [q] Exit\n")
    val action = log.askString("action (examples: 1, 2, 3, 4, q)")

    // Start time
    val start_time = System.nanoTime

    action match {
      case "1" =>
        // Prompt for user ID and no. recommendations via the command line
        val userID = log.askInt("user ID (examples: 1000002, 1000029...)")
        val numRecommendations = log.askInt("number of recommendations (example: 5)")
        log.newLine()
        runRecommender.recommend(rawUserArtistData, rawArtistData, rawArtistAlias, userID, numRecommendations)
      case "2" =>
        // Prompt for user ID via the command line
        val userID = log.askInt("user ID (examples: 1000002, 1000029...)")
        log.newLine()
        runRecommender.showMostListenedRaw(rawUserArtistData, rawArtistData, rawArtistAlias, userID)
      case "3" =>
        log.newLine()
        runRecommender.showStatistics(rawUserArtistData, rawArtistData, rawArtistAlias)
      case "4" =>
        // Prompt for search string
        val searchContent = log.askString("artist name (example: Black Sabbath)")
        log.newLine()
        runRecommender.searchArtist(searchContent, rawArtistData, rawArtistAlias)
      case "5" =>
        log.newLine()
        runRecommender.evaluate(rawUserArtistData, rawArtistAlias)
      case "q" =>
        println("Bye")
        System.exit(0)
      case _ =>
        log.newLine()
        log.error("Unknown action \"" + action + "\"")
    }

    // Log elapsed time
    println("Elapsed time: " + (System.nanoTime - start_time) / 1e9d + "s")
    log.newLine()

    askAction(rawUserArtistData, rawArtistData, rawArtistAlias, runRecommender)
  }
}

class RunRecommender(private val spark: SparkSession) {

  import spark.implicits._

  // Import and declare utils
  val log = new CustomLogger()

  // Seacrh artist in artists dataset and return real alias
  def searchArtist(
    searchContent: String,
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String]
  ): Unit = {

    log.result("Search results")

    val artistByID = buildArtistByID(rawArtistData)
    artistByID.filter($"name".contains(searchContent)).show()

    val bArtistAlias = spark.sparkContext.broadcast(buildArtistAlias(rawArtistAlias))
  }

  // Show dataset statistics
  def showStatistics(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String]
  ): Unit = {

    log.result("Ststistics of the data")

    val userArtistDF = rawUserArtistData.map { line =>
      val Array(user, artist, _*) = line.split(' ')
      (user.toInt, artist.toInt)
    }.toDF("user", "artist")

    userArtistDF.agg(min("user"), max("user"), min("artist"), max("artist")).show()
  }

  // Evaluate data
  def evaluate(
    rawUserArtistData: Dataset[String],
    rawArtistAlias: Dataset[String]
  ): Unit = {

    val bArtistAlias = spark.sparkContext.broadcast(buildArtistAlias(rawArtistAlias))

    val allData = buildCounts(rawUserArtistData, bArtistAlias)
    val Array(trainData, cvData) = allData.randomSplit(Array(0.9, 0.1))
    trainData.cache()
    cvData.cache()

    val allArtistIDs = allData.select("artist").as[Int].distinct().collect()
    val bAllArtistIDs = spark.sparkContext.broadcast(allArtistIDs)

    val evaluations =
      for (rank		  <- Seq(5,	10, 20, 30);
           regParam <- Seq(1.0, 0.0001);
           alpha		<- Seq(1.0, 40.0))
      yield {
        val model = buildALSModel(rank, regParam, alpha, 20, trainData)
        val auc = areaUnderCurve(cvData, bAllArtistIDs, model.transform)

        model.userFactors.unpersist()
        model.itemFactors.unpersist()

        (auc, (rank, regParam, alpha))
      }

    log.result("Evaluations")
    evaluations.sorted.reverse.foreach(println)
    log.newLine()

    trainData.unpersist()
    cvData.unpersist()
  }

  // Make recommendations
  def recommend(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String],
    userID: Int,
    numRecommendations: Int
  ): Unit = {

    val bArtistAlias = spark.sparkContext.broadcast(buildArtistAlias(rawArtistAlias))
    val allData = buildCounts(rawUserArtistData, bArtistAlias).cache()
    val artistByID = buildArtistByID(rawArtistData)

    val model = buildALSModel(20, 1.0, 40.0, 20, allData)

    allData.unpersist()
    showMostListened(rawUserArtistData, bArtistAlias, userID, artistByID, allData)

    val topRecommendations = makeRecommendations(model, userID, numRecommendations)
    val recommendedArtistIDs = topRecommendations.select("artist").as[Int].collect()

    log.result("Showing " + numRecommendations + " recommendations for user " + userID)
    artistByID.join(spark.createDataset(recommendedArtistIDs).toDF("id"), "id").
      select("name").show()

    model.userFactors.unpersist()
    model.itemFactors.unpersist()
  }

  def buildArtistByID(
    rawArtistData: Dataset[String]
  ): DataFrame = {

    rawArtistData.flatMap { line =>
      val (id, name) = line.span(_ != '\t')
      if (name.isEmpty) {
        None
      } else {
        try {
          Some((id.toInt, name.trim))
        } catch {
          case _: NumberFormatException => None
        }
      }
    }.
    toDF("id", "name").
    filter(!$"name".isin("Unknown", "unknown", "[unknown]"))
  }

  def buildArtistAlias(
    rawArtistAlias: Dataset[String]
  ): Map[Int,Int] = {

    rawArtistAlias.flatMap { line =>
      val Array(artist, alias) = line.split('\t')
      if (artist.isEmpty) {
        None
      } else {
        Some((artist.toInt, alias.toInt))
      }
    }.collect().toMap
  }

  def buildCounts(
     rawUserArtistData: Dataset[String],
     bArtistAlias: Broadcast[Map[Int,Int]]
  ): DataFrame = {

    rawUserArtistData.map { line =>
      val Array(userID, artistID, count) = line.split(' ').map(_.toInt)
      val finalArtistID = bArtistAlias.value.getOrElse(artistID, artistID)
      (userID, finalArtistID, count)
    }.toDF("user", "artist", "count")
  }

  def makeRecommendations(
    model: ALSModel,
    userID: Int,
    howMany: Int
  ): DataFrame = {

    val toRecommend = model.itemFactors.
      select($"id".as("artist")).
      withColumn("user", lit(userID))
    model.transform(toRecommend).
      select("artist", "prediction").
      orderBy($"prediction".desc).
      limit(howMany)
  }

  def areaUnderCurve(
    positiveData: DataFrame,
    bAllArtistIDs: Broadcast[Array[Int]],
    predictFunction: (DataFrame => DataFrame)
  ): Double = {

    // What this actually computes is AUC, per user. The result is actually something
    // that might be called "mean AUC".

    // Take held-out data as the "positive".
    // Make predictions for each of them, including a numeric score
    val positivePredictions = predictFunction(positiveData.select("user", "artist")).
      withColumnRenamed("prediction", "positivePrediction")

    // BinaryClassificationMetrics.areaUnderROC is not used here since there are really lots of
    // small AUC problems, and it would be inefficient, when a direct computation is available.

    // Create a set of "negative" products for each user. These are randomly chosen
    // from among all of the other artists, excluding those that are "positive" for the user.
    val negativeData = positiveData.select("user", "artist").as[(Int,Int)].
      groupByKey { case (user, _) => user }.
      flatMapGroups { case (userID, userIDAndPosArtistIDs) =>
        val random = new Random()
        val posItemIDSet = userIDAndPosArtistIDs.map { case (_, artist) => artist }.toSet
        val negative = new ArrayBuffer[Int]()
        val allArtistIDs = bAllArtistIDs.value
        var i = 0
        // Make at most one pass over all artists to avoid an infinite loop.
        // Also stop when number of negative equals positive set size
        while (i < allArtistIDs.length && negative.size < posItemIDSet.size) {
          val artistID = allArtistIDs(random.nextInt(allArtistIDs.length))
          // Only add new distinct IDs
          if (!posItemIDSet.contains(artistID)) {
            negative += artistID
          }
          i += 1
        }
        // Return the set with user ID added back
        negative.map(artistID => (userID, artistID))
      }.toDF("user", "artist")

    // Make predictions on the rest:
    val negativePredictions = predictFunction(negativeData).
      withColumnRenamed("prediction", "negativePrediction")

    // Join positive predictions to negative predictions by user, only.
    // This will result in a row for every possible pairing of positive and negative
    // predictions within each user.
    val joinedPredictions = positivePredictions.join(negativePredictions, "user").
      select("user", "positivePrediction", "negativePrediction").cache()

    // Count the number of pairs per user
    val allCounts = joinedPredictions.
      groupBy("user").agg(count(lit("1")).as("total")).
      select("user", "total")
    // Count the number of correctly ordered pairs per user
    val correctCounts = joinedPredictions.
      filter($"positivePrediction" > $"negativePrediction").
      groupBy("user").agg(count("user").as("correct")).
      select("user", "correct")

    // Combine these, compute their ratio, and average over all users
    val meanAUC = allCounts.join(correctCounts, "user").
      select($"user", ($"correct" / $"total").as("auc")).
      agg(mean("auc")).
      as[Double].first()

    joinedPredictions.unpersist()

    meanAUC
  }

  def predictMostListened(
    train: DataFrame
  )(
    allData: DataFrame
  ): DataFrame = {

    val listenCounts = train.groupBy("artist").
      agg(sum("count").as("prediction")).
      select("artist", "prediction")
    allData.
      join(listenCounts, Seq("artist"), "left_outer").
      select("user", "artist", "prediction")
  }

  // Show most listened artists for a user
  def showMostListened(
    rawUserArtistData: Dataset[String],
    bArtistAlias: Broadcast[Map[Int,Int]],
    userID: Int,
    artistByID: DataFrame,
    trainData: DataFrame
  ): Unit = {

    log.result("Most listened artists by this user")
    val existingArtistIDs = trainData.
      filter($"user" === userID).
      sort(desc("count")).
      select("artist").
      as[Int].
      collect()
    artistByID.filter($"id" isin (existingArtistIDs: _*)).show()
  }

  // Show most listened artists for a user (raw)
  def showMostListenedRaw(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String],
    userID: Int
  ): Unit = {
    val bArtistAlias = spark.sparkContext.broadcast(buildArtistAlias(rawArtistAlias))
    val allData = buildCounts(rawUserArtistData, bArtistAlias).cache()
    val artistByID = buildArtistByID(rawArtistData)
    showMostListened(rawUserArtistData, bArtistAlias, userID, artistByID, allData)
  }

  // Build an ALS model
  def buildALSModel(
    rank: Int,
    regParam: Double,
    alpha: Double,
    maxIterations: Int,
    trainData: DataFrame
  ): ALSModel = {

    val model = new ALS().
      setSeed(Random.nextLong()).
      setImplicitPrefs(true).
      setRank(rank).
      setRegParam(regParam).
      setAlpha(alpha).
      setMaxIter(maxIterations).
      setUserCol("user").
      setItemCol("artist").
      setRatingCol("count").
      setPredictionCol("prediction").
      fit(trainData)
    model
  }
}
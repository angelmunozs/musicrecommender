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

  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder().getOrCreate()

    // Optional, but may help avoid errors due to long lineage
    spark.sparkContext.setCheckpointDir("/tmp/")

    // Parameters
    val dataHome = "/tmp/data/"
    val rawUserArtistData = spark.read.textFile(dataHome + "user_artist_data.txt")
    val rawArtistData = spark.read.textFile(dataHome + "artist_data.txt")
    val rawArtistAlias = spark.read.textFile(dataHome + "artist_alias.txt")

    // Prompt for user ID and no. recommendations via the command line
    log.line()
    val userID = log.ask("user ID (examples: 1000002, 1000029, 1000260...)")
    log.line()
    val numRecommendations = log.ask("number of recommendations (example: 5)")
    log.line()

    // Create new recommender
    val runRecommender = new RunRecommender(spark)

    // Perform recommendation
    runRecommender.recommend(rawUserArtistData, rawArtistData, rawArtistAlias, userID, numRecommendations)
  }
}

class RunRecommender(private val spark: SparkSession) {

  import spark.implicits._

  // Import and declare utils
  val log = new CustomLogger()

  // Prepare data for processing
  def preparation(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String]
  ): Unit = {

    if(log.level >=4) {
      val userArtistDF = rawUserArtistData.map { line =>
        val Array(user, artist, _*) = line.split(' ')
        (user.toInt, artist.toInt)
      }.toDF("user", "artist")
      log.debug("Satistics of the data")
      userArtistDF.agg(min("user"), max("user"), min("artist"), max("artist")).show()
    }
  }

  // Make data model
  def model(
    rawUserArtistData: Dataset[String],
    rawArtistData: Dataset[String],
    rawArtistAlias: Dataset[String],
    userID: Int,
    numRecommendations: Int
  ): Unit = {

    val bArtistAlias = spark.sparkContext.broadcast(buildArtistAlias(rawArtistAlias))

    val trainData = buildCounts(rawUserArtistData, bArtistAlias).cache()
    trainData.unpersist()

    val existingArtistIDs = trainData.
      filter($"user" === userID).
      select("artist").as[Int].collect()

    val artistByID = buildArtistByID(rawArtistData)

    if(log.level >=3) {
      log.debug("Most listened artist by this user")
      artistByID.filter($"id" isin (existingArtistIDs: _*)).show()
    }

    val model = new ALS().
    setSeed(Random.nextLong()).
    setImplicitPrefs(true).
    setRank(10).
    setRegParam(0.01).
    setAlpha(1.0).
    setMaxIter(5).
    setUserCol("user").
    setItemCol("artist").
    setRatingCol("count").
    setPredictionCol("prediction").
    fit(trainData)

    if(log.level >=4) {
      log.debug("Features")
      model.userFactors.select("features").show(truncate = false)
    }

    val topRecommendations = makeRecommendations(model, userID, numRecommendations)

    if(log.level >=4) {
      log.debug("Quality of the recommendations")
      topRecommendations.show()
    }

    val recommendedArtistIDs = topRecommendations.select("artist").as[Int].collect()

    if(log.level >=3) {
      log.info("Recommended artists")
      artistByID.filter($"id" isin (recommendedArtistIDs: _*)).show()
    }

    model.userFactors.unpersist()
    model.itemFactors.unpersist()
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

    if(log.level >=4) {
      log.debug("Most listened area under curve (AUC)")
      val mostListenedAUC = areaUnderCurve(cvData, bAllArtistIDs, predictMostListened(trainData))
      println(mostListenedAUC)
    }

    val evaluations =
      for (rank		  <- Seq(5,	30);
           regParam <- Seq(1.0, 0.0001);
           alpha		<- Seq(1.0, 40.0))
        yield {
          val model = new ALS().
            setSeed(Random.nextLong()).
            setImplicitPrefs(true).
            setRank(rank).
            setRegParam(regParam).
            setAlpha(alpha).
            setMaxIter(20).
            setUserCol("user").
            setItemCol("artist").
            setRatingCol("count").
            setPredictionCol("prediction").
            fit(trainData)

          val auc = areaUnderCurve(cvData, bAllArtistIDs, model.transform)

          model.userFactors.unpersist()
          model.itemFactors.unpersist()

          (auc, (rank, regParam, alpha))
        }

    if(log.level >=3) {
      log.info("Evaluations:")
      evaluations.sorted.reverse.foreach(println)
    }

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
    val model = new ALS().
      setSeed(Random.nextLong()).
      setImplicitPrefs(true).
      setRank(10).
      setRegParam(1.0).
      setAlpha(40.0).
      setMaxIter(20).
      setUserCol("user").
      setItemCol("artist").
      setRatingCol("count").
      setPredictionCol("prediction").
      fit(allData)
    allData.unpersist()

    val topRecommendations = makeRecommendations(model, userID, numRecommendations)

    val recommendedArtistIDs = topRecommendations.select("artist").as[Int].collect()
    val artistByID = buildArtistByID(rawArtistData)

    if(log.level >=3) {
      log.debug("Most listened artist by this user")
      val trainData = buildCounts(rawUserArtistData, bArtistAlias).cache()
      trainData.unpersist()
      val existingArtistIDs = trainData.
        filter($"user" === userID).
        select("artist").as[Int].collect()
      artistByID.filter($"id" isin (existingArtistIDs: _*)).show()
    }

    if(log.level >=4) {
      log.debug("Recommendations")
      artistByID.join(spark.createDataset(recommendedArtistIDs).toDF("id"), "id").
        select("name").show()
    }

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
    }.toDF("id", "name")
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
}
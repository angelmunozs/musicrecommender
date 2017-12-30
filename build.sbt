name := "musicrecommender"
version := "0.1"
scalaVersion := "2.11.12"

// Main class
mainClass in (Compile, run) := Some("Recommender")

// Dependencies
libraryDependencies += "org.scala-lang" % "scala-library" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scalap" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scala-compiler" % "2.11.12"
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.2.1"
libraryDependencies += "org.apache.spark" %% "spark-mllib" % "2.2.1"
libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.2.1"
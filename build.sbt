name := "musicrecommender"
version := "1.0"
scalaVersion := "2.11.12"

// Options
connectInput in run := true

// Dependencies
libraryDependencies += "org.scala-lang" % "scala-library" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scalap" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scala-compiler" % "2.11.12"
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.2.0"
libraryDependencies += "org.apache.spark" %% "spark-mllib" % "2.2.0"
libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.2.0"

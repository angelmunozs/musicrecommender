# musicrecommender

## Documentation

Scala book: [link](http://proquest.safaribooksonline.com/book/databases/business-intelligence/9781491912751/firstchapter).
Repository: [link](https://github.com/sryza/aas).

## Set up dev environment

Execute script `dev.sh`, located inside `bin/`.

```sh
./bin/dev.sh
```

This script will clone/pull the repository into folder `~/www` and download and install dev dependencies into `~/opt`:

* Oracle JDK 8.
* Scala 2.12.4.
* Apache Spark 2.2.0.
* IntelliJ IDEA 2017.2.5.

## Install dependencies

IntelliJ IDEA will automatically detect dependencies on file `build.sbt` and [install them to cache](https://www.scala-lang.org/documentation/getting-started-intellij-track/building-a-scala-project-with-intellij-and-sbt.html).

To add a new Maven-managed dependency, just edit `build.sbt` and add the line that you find when searching the dependency on [Maven Repository](https://mvnrepository.com/) and selecting *sbt*:

```
libraryDependencies += groupID % artifactID % revision
```

If IntelliJ IDEA doesn't automatically update `import` statements when adding a new dependency, read [this article](https://stackoverflow.com/questions/9980869/force-intellij-idea-to-reread-all-maven-dependencies).

Click [here](http://www.scala-sbt.org/1.x/docs/Library-Dependencies.html) to learn more about *sbt* dependencies.

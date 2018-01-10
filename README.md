# musicrecommender

## Documentation

Scala book: [link](http://proquest.safaribooksonline.com/book/databases/business-intelligence/9781491912751/firstchapter).
Repository: [link](https://github.com/sryza/aas).

## Set up dev environment

Execute script `dev.sh`, located inside `bin/`.

```sh
./bin/dev.sh
```

This script will download and install dev dependencies into `/opt`:

* Oracle JDK 8.
* Scala 2.12.4.
* Apache Spark 2.2.0.
* SBT 1.0.4.
* Datasets to be used by the recommender.

## Modify datasets

Execute script `addlog.sh`, located inside `bin/`.

```sh
./bin/addlog.sh
```

It is essential that you have downloaded the datasets previously.

## Execute recommender

There's two different environments you can execute the recommender on:

- **local**, which means that the compiler, the code and Spark will execute on your local machine. The datasets will be read directly from the local file system.
- **docker**, which means that the compiler will be executed on your local machine, Spark will be executed on clustered mode over 5 Docker containers (one master and 4 workers), the code will be executed on Spark master and the datasets will be read from a dockerized Hadoop file system.

To execute any of them, you just need to execute script `run.sh`, located inside `bin/`.

```sh
./bin/run.sh ${ENVIRONMENT} [${OPTIONS}]
```

where `${ENVIRONMENT}` can be either **local** or **docker**, and `${OPTIONS}` can be `--no-compile` (to avoid compiling the code again and just executing the last generated JAR) or none.

### Examples:

```sh
./bin/run.sh local
./bin/run.sh docker
./bin/run.sh local --no-compile
./bin/run.sh docker --no-compile
```

#!/bin/bash

# 1. Lanuch spark
docker-compose up -d

# 2. Launch sbt
$SBT_HOME/bin/sbt
#!/bin/bash
# 1. Lanuch spark from docker-compose.yml
docker-compose up -d
# 2. Generate Dockerfile with master IP
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' musicrecommender_master_1)
cp Dockerfile.dist Dockerfile
find Dockerfile -type f -exec sed -i s/%MASTER_IP%/$MASTER_IP/g {} \;
# 3. Launch recommender from custom Dockerfile
docker build -t musicrecommender .

# To run local:
# sbt compile && \
# sbt package && \
# /opt/spark-2.2.0-bin-hadoop2.7/bin/spark-submit \ 
# --class RunRecommender \
# --master spark://172.17.0.2:7077 \
# ./target/scala-2.11/musicrecommender_2.11-0.1.jar
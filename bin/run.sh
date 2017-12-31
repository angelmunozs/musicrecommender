# 1. Lanuch spark from docker-compose.yml
docker-compose up -d
# 2. Generate Dockerfile with master IP
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' musicrecommender_master_1)
cp Dockerfile.dist Dockerfile
find Dockerfile -type f -exec sed -i s/%MASTER_IP%/$MASTER_IP/g {} \;
# 3. Launch recommender from custom Dockerfile
docker build -t musicrecommender .
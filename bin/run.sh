#!/bin/bash
set -e

# ==============================================================================================================
# Dependencies
# ==============================================================================================================

# Common parameters and functions
source bin/common.sh

# ==============================================================================================================
# Functions
# ==============================================================================================================

# Usage
print_usage () {
    echo "Usage: "
    echo " ./bin/run.sh \${ENVIRONMENT}"
    echo "Parameters: "
    echo " - \${ENVIRONMENT}: desired environment (\"local\" or \"docker\")"
    echo "Examples: "
    echo " ./bin/run.sh local"
    echo " ./bin/run.sh docker"
    exit 1
}

# Run locally
run_local () {
    # 1. Compile and pack with SBT
    generate_jar
    # 2. Generate env.properties file
    generate_properties "file:///home/angel/www/musicrecommender/data"
    # 3. Launch recommender with spark-submit after copying data to /tmp/data
    execute_jar "local[*]"
}

# Run locally
run_docker () {
    # 1. Launch spark from docker-compose.yml
    spark_init_docker
    # 2. Compile and pack with SBT
    generate_jar
    # 3. Generate env.properties file
    generate_properties "file:///tmp/data"
    # 4. Launch recommender with spark-submit after copying data to /tmp/data
    execute_jar "spark://$(get_master_ip):7077"
}

# Execute JAR with spark-submit
execute_jar () {
    log_info "Executing recommender with spark-submit"
    $INSTALLS_DIR/spark/bin/spark-submit \
    --class "RunRecommender" \
    --master "$1" \
    --executor-memory 8G \
    --total-executor-cores 4 \
    ./target/scala-$SCALA_SHORT_VERSION/musicrecommender_$SCALA_SHORT_VERSION-$PROJECT_VERSION.jar
}

# Generate conf/general/env.properties file
generate_properties () {
    # 1. Create directory conf/geeral if not existing
    mkdir -p conf/general
    # 2. Echo content to file conf/general/env.properties
    echo "DATA_HOME=$1" > conf/general/env.properties
}

# Compile and package code
generate_jar () {
    # Compile code with SBT
    log_info "Compiling recommender code"
    $INSTALLS_DIR/sbt/bin/sbt compile
    # Create JAR with SBT
    log_info "Packaging compiled recommender code"
    $INSTALLS_DIR/sbt/bin/sbt package
}

# Launch Spark master and workers
spark_init_docker () {
    # Launch spark from docker-compose.yml
    log_info "Initializing Spark from docker-compose.yml"
    docker-compose up -d
}

# Get Spark master IP
get_master_ip () {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' musicrecommender_master_1
}

# ==============================================================================================================
# Main
# ==============================================================================================================

# Execution depending on parameters
if [ -z $1 ]; then
    log_error "No environment selected"
    print_usage
else
    case "$1" in
        local)
            run_local
        ;;
        docker)
            run_docker
        ;;
        *)
            log_error "Unknown environment \"$1\""
            print_usage
        ;;
    esac
fi

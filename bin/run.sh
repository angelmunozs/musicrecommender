#!/bin/bash

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

# Compile and package code
generate_jar () {
    # Compile code with SBT
    log_info "Compiling recommender code"
    $INSTALLS_DIR/sbt/bin/sbt compile
    # Create JAR with SBT
    log_info "Packaging compiled recommender code"
    $INSTALLS_DIR/sbt/bin/sbt package
}

# Run locally
run_local () {
    # 1. Compile and pack with SBT
    generate_jar
    # 2. Launch recommender with spark-submit after copying data to /tmp/data
    log_info "Executing recommender with spark-submit"
    $INSTALLS_DIR/spark/bin/spark-submit \
    --class "RunRecommender" \
    --master "local[*]" \
    --executor-memory 4G \
    --total-executor-cores 4 \
    ./target/scala-2.11/musicrecommender_2.11-0.1.jar
}

# Run locally
run_docker () {
    # 1. Launch spark from docker-compose.yml
    spark_init
    # 2. Compile and pack with SBT
    generate_jar
    # 3. Launch recommender with spark-submit after copying data to /tmp/data
    log_info "Executing recommender with spark-submit"
    $INSTALLS_DIR/spark/bin/spark-submit \
    --class "RunRecommender" \
    --master "spark://$(get_master_ip):7077" \
    --executor-memory 4G \
    --total-executor-cores 4 \
    ./target/scala-2.11/musicrecommender_2.11-0.1.jar
}

# Launch Spark master and workers
spark_init () {
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

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
    echo " - \${OPTIONS}:     options (\"--no-compile\")."
    echo "Examples: "
    echo " ./bin/run.sh local"
    echo " ./bin/run.sh docker"
    echo " ./bin/run.sh docker --no-compile"
    exit 1
}

# Run locally
# Parameters:
# - $1: Options. Possible values: --no-compile (to avoid compiling code again).
run_local () {
    # 1. Compile and pack with SBT
    generate_jar $1
    # 2. Generate env.properties file
    generate_properties "file:///home/angel/www/musicrecommender/data"
    # 3. Launch recommender with spark-submit after copying data to /tmp/data
    execute_jar "local[*]"
}

# Run locally
# Parameters:
# - $1: Options. Possible values: --no-compile (to avoid compiling code again).
run_docker () {
    # 1. Launch spark from docker-compose.yml
    spark_init_docker
    # 2. Compile and pack with SBT
    generate_jar $1
    # 3. Generate env.properties file
    generate_properties "hdfs://$(get_ip musicrecommender_worker_1):9000/tmp/data"
    # 4. Launch recommender with spark-submit after copying data to /tmp/data
    execute_jar "spark://$(get_ip musicrecommender_master_1):7077"
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
# Parameters:
# - $1: Options. Possible values: --no-compile (to avoid compiling code again).
generate_jar () {
    if [ "$1" != "--no-compile" ]; then
        # Compile code with SBT
        log_info "Compiling recommender code"
        $INSTALLS_DIR/sbt/bin/sbt compile
        # Create JAR with SBT
        log_info "Packaging compiled recommender code"
        $INSTALLS_DIR/sbt/bin/sbt package
    fi
}

# Launch Spark master and workers
spark_init_docker () {
    # Launch spark from docker-compose.yml
    log_info "Initializing Spark from docker-compose.yml"
    docker-compose up -d
}

# Get the IP of a docker container
get_ip () {
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1
}

# ==============================================================================================================
# Main
# ==============================================================================================================

# Execution depending on parameters
# Parameters:
# - $1: Environment. Possible values: local, docker.
# - $2: Optional. Possible values: --no-compile (to avoid compiling code again).

# Exit if no first parameter
if [ -z $1 ]; then
    log_error "No environment selected"
    print_usage
fi

# Exit if unknown option
if [ ! -z $2 ] && [ "$2" != "--no-compile" ]; then
    log_error "Unknown option \"$2\""
    print_usage
fi

# Main functionality
case "$1" in
    local)
        run_local $2
    ;;
    docker)
        run_docker $2
    ;;
    *)
        log_error "Unknown environment \"$1\""
        print_usage
    ;;
esac

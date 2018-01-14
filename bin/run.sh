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
    echo " ./bin/run.sh \${ENVIRONMENT} [\${OPTIONS}]"
    echo "Parameters: "
    echo " - 1st parameter: environment (required). Values: \"local\" or \"docker\"."
    echo " - 2nd parameter: options (not required). Values: \"--no-compile\"."
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
    # 2. Launch recommender with spark-submit
    execute_jar_locally "file://$PROJECTS_LOCATION/$PROJECT_NAME"
}

# Run in dockerized Spark and Hadoop
# Parameters:
# - $1: Options. Possible values: --no-compile (to avoid compiling code again).
run_docker () {
    # 1. Launch spark from docker-compose.yml
    spark_init_docker
    # 2. Compile and pack with SBT
    generate_jar $1
    # 3. Launch recommender with spark-submit
    execute_jar_in_master "hdfs://$(get_ip musicrecommender_hadoop_1):9000/user"
}

# Execute JAR with spark-submit
# Parameters:
# - $1: Data home, to be read by main JAR.
execute_jar_locally () {
    log_info "Executing recommender locally with spark-submit"
    $INSTALLS_DIR/spark/bin/spark-submit \
    --driver-cores 4 \
    --driver-memory 16G \
    --class "RunRecommender" \
    --master "local[*]" \
    ./target/scala-$SCALA_SHORT_VERSION/musicrecommender_$SCALA_SHORT_VERSION-$PROJECT_VERSION.jar $1
}

# Execute JAR in Spark master
# Parameters:
# - $1: Data home, to be read by main JAR.
execute_jar_in_master () {
    log_info "Executing recommender in Spark master with spark-submit"
    docker exec -it musicrecommender_master_1 bin/spark-submit \
    --driver-cores 4 \
    --driver-memory 16G \
    --class "RunRecommender" \
    --master "spark://$(get_ip musicrecommender_master_1):7077" \
    /tmp/target/scala-$SCALA_SHORT_VERSION/musicrecommender_$SCALA_SHORT_VERSION-$PROJECT_VERSION.jar $1
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
    print_usage
fi

# Exit if unknown option
if [ ! -z $2 ] && [ "$2" != "--no-compile" ]; then
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
        print_usage
    ;;
esac

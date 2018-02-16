#!/bin/bash -x

# This build script is only applicable to Spark without Hadoop and Hive

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`

WORKSPACE=${WORKSPACE:-"$curr_dir/workspace"}
mkdir -p $WORKSPACE
sparkexample_git_dir=$WORKSPACE/sparkexample
git_hash=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

env | sort

if [ "x${PACKAGE_BRANCH}" = "x" ] ; then
  echo "error - PACKAGE_BRANCH is not defined. Please specify the branch explicitly. Exiting!"
  exit -9
fi

echo "ok - extracting git commit label from user defined $PACKAGE_BRANCH"
pushd $sparkexample_git_dir
git_hash=$(git rev-parse HEAD | tr -d '\n')
echo "ok - we are compiling spark branch $PACKAGE_BRANCH upto commit label $git_hash"
popd

# Get a copy of the source code, and tar ball it, remove .git related files
# Rename directory from spark to alti-spark to distinguish 'spark' just in case.
echo "ok - preparing to compile, build, and packaging spark"

if [ "x${HADOOP_VERSION}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=$HADOOP_VERSION
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x${HIVE_VERSION}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=$HIVE_VERSION
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi

pushd $WORKSPACE
pushd $sparkexample_git_dir/

echo "ok - building Spark examples in directory $(pwd) with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION scala=scala-${SCALA_VERSION}"

env | sort


# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

########################
# BUILD ENTIRE PACKAGE #
########################
# This will build the overall JARs we need in each folder
# and install them locally for further reference. We assume the build
# environment is clean, so we don't need to delete ~/.ivy2 and ~/.m2
# Default JDK version applied is 1.7 here.

# hadoop.version, yarn.version, and hive.version are all defined in maven profile now
# they are tied to each profile.
# hadoop-2.2 No longer supported, removed.
# hadoop-2.4 hadoop.version=2.4.1 yarn.version=2.4.1 hive.version=0.13.1a hive.short.version=0.13.1
# hadoop-2.6 hadoop.version=2.6.0 yarn.version=2.6.0 hive.version=1.2.1.spark hive.short.version=1.2.1
# hadoop-2.7 hadoop.version=2.7.1 yarn.version=2.7.1 hive.version=1.2.1.spark hive.short.version=1.2.1

testcase_hadoop_profile_str=""
if [[ $SPARK_HADOOP_VERSION == 2.4.* ]] ; then
  testcase_hadoop_profile_str="-Phadoop24-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.6.* ]] ; then
  testcase_hadoop_profile_str="-Phadoop26-provided"
elif [[ $SPARK_HADOOP_VERSION == 2.7.* ]] ; then
  testcase_hadoop_profile_str="-Phadoop27-provided"
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi

# TODO: This needs to align with Maven settings.xml, however, Maven looks for
# -SNAPSHOT in pom.xml to determine which repo to use. This creates a chain reaction on 
# legacy pom.xml design on other application since they are not implemented in the Maven way.
# :-( 
# Will need to create a work around with different repo URL and use profile Id to activate them accordingly
# mvn_release_flag=""
# if [ "x%{_production_release}" == "xtrue" ] ; then
#   mvn_release_flag="-Preleases"
# else
#   mvn_release_flag="-Psnapshots"
# fi

echo "ok - pre-installing JARs provided by alti-spark-${SPARK_VERSION}"
mvn_install_target_repo=""
if [ -d "$WORKSPACE/.m2" ] ; then
  mvn_install_target_repo="-DlocalRepositoryPath=$WORKSPACE/.m2/repository"
fi
mvn_install_cmd="mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Duserdef.spark.version=${SPARK_VERSION} -Duserdef.hadoop.version=$SPARK_HADOOP_VERSION -Dversion=${SPARK_VERSION} -Dpackaging=jar -DgroupId=local.org.apache.spark"
# This applies to local integration with Spark assembly JARs
$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/core/target/spark-core_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-core_${SCALA_VERSION} $mvn_install_target_repo

# For Kafka Spark Streaming Examples
$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/external/kafka-0-8/target/spark-streaming-kafka-0-8_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-streaming-kafka-0-8_${SCALA_VERSION} $mvn_install_target_repo

$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/streaming/target/spark-streaming_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-streaming_${SCALA_VERSION} $mvn_install_target_repo

# For SparkSQL Hive integration examples, this is required when you use -Phive-provided
# spark-hive JAR needs to be provided to the test case in this case.
$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/sql/core/target/spark-sql_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-sql_${SCALA_VERSION} $mvn_install_target_repo

$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/sql/catalyst/target/spark-catalyst_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-catalyst_${SCALA_VERSION} $mvn_install_target_repo

$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/sql/hive/target/spark-hive_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-hive_${SCALA_VERSION} $mvn_install_target_repo

# Additional dependencies
$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/common/unsafe/target/spark-unsafe_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-unsafe_${SCALA_VERSION} $mvn_install_target_repo

$mvn_install_cmd -Dfile=/opt/alti-spark-${SPARK_VERSION}/common/tags/target/spark-tags_${SCALA_VERSION}-${SPARK_VERSION}.jar -DartifactId=spark-tags_${SCALA_VERSION} $mvn_install_target_repo

DEBUG_MAVEN=${DEBUG_MAVEN:-"false"}
if [ "x${DEBUG_MAVEN}" = "xtrue" ] ; then
  mvn_cmd="mvn -U -X package -Pspark-2.2 -Pkafka-provided $testcase_hadoop_profile_str"
else
  mvn_cmd="mvn -U package -Pspark-2.2 -Pkafka-provided $testcase_hadoop_profile_str"
fi

echo "$mvn_cmd"
$mvn_cmd

if [ $? -ne "0" ] ; then
  echo "fail - sparkexample  build failed!"
  popd
  exit -99
fi

popd

echo "ok - build sparkexample completed successfully!"
popd

exit 0

#!/bin/bash

# TBD: honor system pre-defined property/variable files from 
# /etc/hadoop/ and other /etc config for spark, hdfs, hadoop, etc

# Force to use default Java which is JDK 1.7 now
export JAVA_HOME=${JAVA_HOME:-"/usr/java/default"}
export ANT_HOME=${ANT_HOME:-"/opt/apache-ant"}
export MAVEN_HOME=${MAVEN_HOME:-"/usr/share/apache-maven"}
export M2_HOME=${M2_HOME:-"/usr/share/apache-maven"}
export MAVEN_OPTS=${MAVEN_OPTS:-"-Xmx2g -XX:MaxPermSize=1024M -XX:ReservedCodeCacheSize=512m"}
export SCALA_HOME=${SCALA_HOME:-"/opt/scala"}
export HADOOP_VERSION=${HADOOP_VERSION:-"2.7.1"}
# Spark 1.5+ default Hive starts with 1.2.1, backward compatible with Hive 1.2.0
export HIVE_VERSION=${HIVE_VERSION:-"2.1.1"}

export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin:$R_HOME

# Define default spark uid:gid and build version
# and all other Spark build related env
export SPARKEXAMPLE_PKG_NAME=${SPARKEXAMPLE_PKG_NAME:-"sparkexample"}
export SPARK_VERSION=${SPARK_VERSION:-"2.2.1"}
export SCALA_VERSION=${SCALA_VERSION:-"2.11"}

# After AE-1667, no longer need to specify Hadoop and Hive version.
# into the RPM pkg name
if [[ $SPARK_VERSION == 2.* ]] ; then
  if [[ $SCALA_VERSION != 2.11 ]] ; then
    2>&1 echo "error - scala version requires 2.11+ for Spark $SPARK_VERSION, can't continue building, exiting!"
    exit -1
  fi
fi

# Defines which Hadoop version to build against. Always use the latest as default.
export ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-"5.0.0"}
if [[ $HADOOP_VERSION == 2.2.* ]] ; then
  TARGET_ALTISCALE_RELEASE=2.0.0
elif [[ $HADOOP_VERSION == 2.4.* ]] ; then
  TARGET_ALTISCALE_RELEASE=3.0.0
elif [[ $HADOOP_VERSION == 2.[67].* ]] ; then
  TARGET_ALTISCALE_RELEASE=4.0.0
elif [[ $HADOOP_VERSION == 2.8.* ]] ; then
  TARGET_ALTISCALE_RELEASE=5.0.0
else
  2>&1 echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION for $ALTISCALE_RELEASE"
  2>&1 echo "error - $SPARK_VERSION has not yet been tested nor endorsed by Altiscale on $HADOOP_VERSION"
  2>&1 echo "error - We won't continue to build Spark $SPARK_VERSION, exiting!"
  exit -1
fi
# Sanity check on RPM label integration and Altiscale release label
if [ $TARGET_ALTISCALE_RELEASE -ne $ALTISCALE_RELEASE ] ; then
  2>&1 echo "fatal - you specified $ALTISCALE_RELEASE that is not verified by $SPARK_VERSION yet"
  2>&1 echo "fatal - releasing this will potentially break Spark installaion or Hadoop compatibility, exiting!"
  exit -2
fi

export BUILD_TIMEOUT=${BUILD_TIMEOUT:-"86400"}
# centos6.5-x86_64
# centos6.6-x86_64
# centos6.7-x86_64
export BUILD_ROOT=${BUILD_ROOT:-"centos6.5-x86_64"}
export BUILD_TIME=$(date +%Y%m%d%H%M)
# Customize build OPTS for MVN
export MAVEN_OPTS=${MAVEN_OPTS:-"-Xmx2048m -XX:MaxPermSize=1024m"}
export PRODUCTION_RELEASE=${PRODUCTION_RELEASE:-"false"}

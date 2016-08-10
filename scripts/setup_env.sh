#!/bin/bash

# TBD: honor system pre-defined property/variable files from 
# /etc/hadoop/ and other /etc config for spark, hdfs, hadoop, etc

# Force to use default Java which is JDK 1.7 now
export JAVA_HOME=/usr/java/default

if [ "x${ANT_HOME}" = "x" ] ; then
  export ANT_HOME=/opt/apache-ant
fi
if [ "x${MAVEN_HOME}" = "x" ] ; then
  export MAVEN_HOME=/usr/share/apache-maven
fi
if [ "x${M2_HOME}" = "x" ] ; then
  export M2_HOME=/usr/share/apache-maven
fi
if [ "x${MAVEN_OPTS}" = "x" ] ; then
  export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024M -XX:ReservedCodeCacheSize=512m"
fi
if [ "x${SCALA_HOME}" = "x" ] ; then
  export SCALA_HOME=/opt/scala
fi
if [ "x${SCALA_VERSION}" = "x" ] ; then
  export SCALA_VERSION=2.11
fi
if [ "x${HADOOP_VERSION}" = "x" ] ; then
  export HADOOP_VERSION=2.7.1
fi
# Spark 1.5+ default Hive starts with 1.2.1, backward compatible with Hive 1.2.0
if [ "x${HIVE_VERSION}" = "x" ] ; then
  export HIVE_VERSION=1.2.1
fi
# AE-1226 temp fix on the R PATH
# if [ "x${R_HOME}" = "x" ] ; then
#   # AE-1222 an ugly way to guess where is R_HOME
#   export R_HOME=$(dirname $(dirname $(rpm -ql $(rpm -qa | grep vcc-R_.*-0.2.0- | sort -r | head -n 1 ) | grep bin | head -n 1)))
#   if [ "x${R_HOME}" = "x" ] ; then
#     echo "warn - R_HOME not defined, CRAN R isn't installed properly in the current env"
#   else
#     echo "ok - R_HOME redefined to $R_HOME based on installed RPM due to AE-1226"
#   fi
# fi

export PATH=$PATH:$M2_HOME/bin:$SCALA_HOME/bin:$ANT_HOME/bin:$JAVA_HOME/bin:$R_HOME

# Define default spark uid:gid and build version
# and all other Spark build related env
if [ "x${SPARKEXAMPLE_PKG_NAME}" = "x" ] ; then
  export SPARKEXAMPLE_PKG_NAME=sparkexample
fi
if [ "x${SPARK_VERSION}" = "x" ] ; then
  export SPARK_VERSION=2.0.0
fi
if [ "x${SPARK_PLAIN_VERSION}" = "x" ] ; then
  export SPARK_PLAIN_VERSION=2.0.0
fi

# Defines which Hadoop version to build against
HADOOP_BUILD_VERSION=$HADOOP_VERSION

# After AE-1667, no longer need to specify Hadoop and Hive version.
# into the RPM pkg name

if [ "x${ALTISCALE_RELEASE}" = "x" ] ; then
  if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
    ALTISCALE_RELEASE=2.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
    ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
    ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.7.0" ] ; then
    ALTISCALE_RELEASE=4.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.7.1" ] ; then
    ALTISCALE_RELEASE=4.0.0
  else
    echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION for ALTISCALE_RELEASE"
    exit -1
  fi 
else
  # OVerride human mistake
  if [ "x${HADOOP_VERSION}" = "x2.2.0" ] ; then
    ALTISCALE_RELEASE=2.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.0" ] ; then
    ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.4.1" ] ; then
    ALTISCALE_RELEASE=3.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.6.0" ] ; then
    ALTISCALE_RELEASE=4.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.7.0" ] ; then
    ALTISCALE_RELEASE=4.0.0
  elif [ "x${HADOOP_VERSION}" = "x2.7.1" ] ; then
    ALTISCALE_RELEASE=4.0.0
  else
    echo "error - can't recognize altiscale's HADOOP_VERSION=$HADOOP_VERSION for ALTISCALE_RELEASE"
    exit -1
  fi
fi 
export ALTISCALE_RELEASE

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  export BUILD_TIMEOUT=86400
fi

BUILD_TIME=$(date +%Y%m%d%H%M)
export BUILD_TIME

BUILD_ROOT=${BUILD_ROOT:-"centos6.5-x86_64"}


# Customize build OPTS for MVN
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"

if [ "x${PRODUCTION_RELEASE}" = "x" ] ; then
  export PRODUCTION_RELEASE=false
fi
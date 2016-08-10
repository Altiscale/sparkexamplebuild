%global apache_name           SPARKEXAMPLE_PKG_NAME

%define production_release    PRODUCTION_RELEASE
%define git_hash_release      GITHASH_REV_RELEASE
%define altiscale_release_ver ALTISCALE_RELEASE
%define parent_rpm_pkg_name   alti-spark
%define spark_version         SPARK_VERSION_REPLACE
%define current_workspace     CURRENT_WORKSPACE_REPLACE
%define hadoop_version        HADOOP_VERSION_REPLACE
%define hadoop_build_version  HADOOP_BUILD_VERSION_REPLACE
%define hive_version          HIVE_VERSION_REPLACE
%define scala_build_version   SCALA_BUILD_VERSION_REPLACE
%define build_service_name    alti-sparkexample
%define spark_folder_name     %{parent_rpm_pkg_name}-%{spark_version}
%define spark_testsuite_name  %{spark_folder_name}
%define install_spark_label   /opt/%{spark_testsuite_name}/test_spark/VERSION
%define install_spark_test    /opt/%{spark_testsuite_name}/test_spark
%define build_release         BUILD_TIME

Name: %{parent_rpm_pkg_name}-%{spark_version}-example
Summary: The Altiscale spark example provided for Spark 2.0+, requires %{parent_rpm_pkg_name}-%{spark_version} RPM to be installed first.
Version: %{spark_version}
# Keep the format here for backward compatibility
Release: %{altiscale_release_ver}.%{build_release}%{?dist}
License: Apache Software License 2.0
Group: Development/Libraries
Source: %{_sourcedir}/%{build_service_name}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{release}-root-%{build_service_name}
Requires(pre): shadow-utils
Requires: scala = 2.11.8
Requires: %{parent_rpm_pkg_name}-%{spark_version}
BuildRequires: %{parent_rpm_pkg_name}-%{spark_version}
BuildRequires: %{parent_rpm_pkg_name}-%{spark_version}-devel
# BuildRequires: vcc-hive-%{hive_version}
BuildRequires: scala = 2.11.8
BuildRequires: apache-maven >= 3.3.9
BuildRequires: jdk >= 1.7.0.51
# For SparkR, prefer R 3.1.2, but we only have 3.1.1
BuildRequires: vcc-R_3.0.3

Url: http://spark.apache.org/
%description
Build from https://github.com/Altiscale/sparkexample/tree/branch-2.0-alti with 
build script https://github.com/Altiscale/sparkexamplebuild/tree/branch-2.0-alti
This provides Altiscale test case around Spark starting from Spark %{spark_version}
in its own RPM %{parent_rpm_pkg_name}-%{spark_version}-example

%pre

%prep

%setup -q -n %{build_service_name}

%build
if [ "x${SCALA_HOME}" = "x" ] ; then
  echo "ok - SCALA_HOME not defined, trying to set SCALA_HOME to default location /opt/scala/"
  export SCALA_HOME=/opt/scala/
fi
# AE-1226 temp fix on the R PATH
if [ "x${R_HOME}" = "x" ] ; then
  export R_HOME=$(dirname $(dirname $(rpm -ql $(rpm -qa | grep vcc-R_.*-0.2.0- | sort -r | head -n 1 ) | grep bin | head -n 1)))
  if [ "x${R_HOME}" = "x" ] ; then
    echo "warn - R_HOME not defined, CRAN R isn't installed properly in the current env"
  else
    echo "ok - R_HOME redefined to $R_HOME based on installed RPM due to AE-1226"
    export PATH=$PATH:$R_HOME
  fi
fi
if [ "x${JAVA_HOME}" = "x" ] ; then
  export JAVA_HOME=/usr/java/default
  # Hijack JAva path to use our JDK 1.7 here instead of openjdk
  export PATH=$JAVA_HOME/bin:$PATH
fi
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=1024m"

echo "build - entire spark project in %{_builddir}"
pushd `pwd`
pushd %{_builddir}/%{build_service_name}/

if [ "x%{hadoop_version}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HADOOP_VERSION=%{hadoop_version}
  echo "ok - applying customized hadoop version $SPARK_HADOOP_VERSION"
fi

if [ "x%{hadoop_build_version}" = "x" ] ; then
  echo "fatal - hadoop_build_version needs to be set, can't build anything, exiting"
  exit -8
fi

if [ "x%{hive_version}" = "x" ] ; then
  echo "fatal - HIVE_VERSION needs to be set, can't build anything, exiting"
  exit -8
else
  export SPARK_HIVE_VERSION=%{hive_version}
  echo "ok - applying customized hive version $SPARK_HIVE_VERSION"
fi

env | sort

echo "ok - building assembly with HADOOP_VERSION=$SPARK_HADOOP_VERSION HIVE_VERSION=$SPARK_HIVE_VERSION scala=scala-%{scala_build_version}"

hadoop_profile_str=""
testcase_hadoop_profile_str=""
if [[ %{hadoop_version} == 2.4.* ]] ; then
  hadoop_profile_str="-Phadoop-2.4"
  testcase_hadoop_profile_str="-Phadoop24-provided"
elif [[ %{hadoop_version} == 2.6.* ]] ; then
  hadoop_profile_str="-Phadoop-2.6"
  testcase_hadoop_profile_str="-Phadoop26-provided"
elif [[ %{hadoop_version} == 2.7.* ]] ; then
  hadoop_profile_str="-Phadoop-2.7"
  testcase_hadoop_profile_str="-Phadoop27-provided"
else
  echo "fatal - Unrecognize hadoop version $SPARK_HADOOP_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi
xml_setting_str=""
if [ -f /etc/alti-maven-settings/settings.xml ] ; then
  echo "ok - applying local maven repo settings.xml for first priority"
  xml_setting_str="--settings /etc/alti-maven-settings/settings.xml --global-settings /etc/alti-maven-settings/settings.xml"
else
  echo "ok - applying default repository form pom.xml"
  xml_setting_str=""
fi

echo "ok - local repository will be installed under %{current_workspace}/.m2/repository"
# TODO: Install local JARs to local repo so we apply the latest built assembly JARs from above
# This is a workaround(hack). A better way is to deploy it to SNAPSHOT on Archiva via maven-deploy plugin,
# and include it in the test_case pom.xml. This is really annoying.

# In mock environment, .m2 may end up somewhere differently, use default in mock.
# explicitly if we detect .m2/repository in local sandbox, etc.
mvn_install_target_repo=""
if [ -d "%{current_workspace}/.m2" ] ; then
  mvn_install_target_repo="-DlocalRepositoryPath=%{current_workspace}/.m2/repository"
fi

# This applies to local integration with Spark assembly JARs
mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/core/target/spark-core_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-core_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo

# For Kafka Spark Streaming Examples
mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/external/kafka-0-8/target/spark-streaming-kafka-0-8_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming-kafka-0-8_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo

mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/streaming/target/spark-streaming_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-streaming_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo

# For SparkSQL Hive integration examples, this is required when you use -Phive-provided
# spark-hive JAR needs to be provided to the test case in this case.
mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/sql/core/target/spark-sql_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-sql_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo
mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/sql/catalyst/target/spark-catalyst_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-catalyst_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo
mvn -U org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=/opt/%{parent_rpm_pkg_name}-%{spark_version}/sql/hive/target/spark-hive_%{scala_build_version}-%{spark_version}.jar -DgroupId=local.org.apache.spark -DartifactId=spark-hive_%{scala_build_version} -Dversion=%{spark_version} -Dpackaging=jar $mvn_install_target_repo

# Build our test case with our own pom.xml file
# Update profile ID spark-1.4 for 1.4.1, spark-1.5 for 1.5.2, spark-1.6 for 1.6.0, and hadoop version hadoop24-provided or hadoop27-provided as well
mvn -U package -Pspark-2.0 -Pkafka-provided $testcase_hadoop_profile_str
popd
echo "ok - build spark example and test case completed successfully!"
popd

%install
# manual cleanup for compatibility, and to be safe if the %clean isn't implemented
rm -rf %{buildroot}%{install_spark_test}
echo "compiled/built folder is (not the same as buildroot) RPM_BUILD_DIR = %{_builddir}"
echo "test installtion folder (aka buildroot) is RPM_BUILD_ROOT = %{buildroot}"
echo "test install spark dest = %{buildroot}/%{install_spark_test}"
%{__mkdir} -p %{buildroot}%{install_spark_test}

# This will capture the installation property form this spec file for further references
rm -f %{buildroot}/%{install_spark_label}
touch %{buildroot}/%{install_spark_label}
echo "name=%{name}" >> %{buildroot}/%{install_spark_label}
echo "version=%{spark_version}" >> %{buildroot}/%{install_spark_label}
echo "release=%{name}-%{release}" >> %{buildroot}/%{install_spark_label}
echo "git_rev=%{git_hash_release}" >> %{buildroot}/%{install_spark_label}

# deploy test suite and scripts
cp -rp %{_builddir}/%{build_service_name}/* %{buildroot}/%{install_spark_test}/

%clean
echo "ok - cleaning up temporary files, deleting %{buildroot}%{install_spark_test}"
rm -rf %{buildroot}%{install_spark_test}

%files
%defattr(0755,root,root,0755)
%{install_spark_test}

%post
if [ "$1" = "1" ]; then
  echo "ok - performing fresh installation"
elif [ "$1" = "2" ]; then
  echo "ok - upgrading system"
fi

%postun
if [ "$1" = "0" ]; then
  ret=$(rpm -qa | grep %{parent_rpm_pkg_name} | grep example wc -l)
  # The rpm is already uninstall and shouldn't appear in the counts
  if [ "x${ret}" != "x0" ] ; then
    echo "ok - cleaning up version specific directories only regarding this uninstallation"
    rm -vrf %{install_spark_test}
  else
    echo "ok - uninstalling %{parent_rpm_pkg_name} on system, removing symbolic links"
    rm -vrf %{install_spark_test}
  fi
fi
# Don't delete the users after uninstallation.

%changelog
* Tue Aug 2 2016 Andrew Lee 20160802
- Initial Creation of spec file for Spark 2.0.0 Examples
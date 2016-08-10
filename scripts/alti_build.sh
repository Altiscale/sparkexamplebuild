#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
workspace_dir=$curr_dir
sparkexample_git_dir=$workspace_dir/../sparkexample

sparkexample_spec="$curr_dir/sparkexample.spec"

mock_cfg="$curr_dir/altiscale-sparkexample-centos-6-noarch.cfg"
mock_cfg_name=$(basename "$mock_cfg")
mock_cfg_runtime=`echo $mock_cfg_name | sed "s/.cfg/.runtime.cfg/"`
build_timeout=28800

maven_settings="$HOME/.m2/settings.xml"
maven_settings_spec="$curr_dir/alti-maven-settings.spec"
workspace_rpm_dir=$workspace_dir/workspace_rpm
mkdir -p $workspace_rpm_dir

git_hash=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
  source "$curr_dir/setup_env.sh"
  set +a
fi

if [ "x${SPARK_VERSION}" = "x" ] ; then
  echo >&2 "fail - SPARK_VERSION can't be empty"
  exit -8
else
  echo "ok - SPARK_VERSION=$SPARK_VERSION"
fi

if [ "x${SPARK_PLAIN_VERSION}" = "x" ] ; then
  echo >&2 "fail - SPARK_PLAIN_VERSION can't be empty"
  exit -8
else
  echo "ok - SPARK_PLAIN_VERSION=$SPARK_PLAIN_VERSION"
fi

if [ "x${BUILD_TIMEOUT}" = "x" ] ; then
  build_timeout=28800
else
  build_timeout=$BUILD_TIMEOUT
fi

if [ ! -f "$maven_settings" ]; then
  echo "fatal - $maven_settings DOES NOT EXIST!!!! YOU MAY PULLING IN UNTRUSTED artifact and BREACH SECURITY!!!!!!"
  exit -9
fi

if [ ! -e "$sparkexample_spec" ] ; then
  echo "fail - missing $sparkexample_spec file, can't continue, exiting"
  exit -9
fi

cleanup_secrets()
{
  local build_dir=$1
  # Erase our track for any sensitive credentials if necessary
  rm -vf $build_dir/alti-maven-settings*.rpm
  rm -vrf $build_dir/alti-maven-settings
  rm -vf $build_dir/alti-maven-settings.tar.gz 
}

env | sort

if [ "x${SPARK_BRANCH_NAME}" = "x" ] ; then
  echo "error - SPARK_BRANCH_NAME is not defined, even though, you may checkout the code from hadoop_ecosystem_component_build, this does not gurantee you have the right branch. Please specify the BRANCH_NAME explicitly. Exiting!"
  exit -9
fi

echo "ok - switching to spark branch $SPARK_BRANCH_NAME and refetch the files"
pushd $sparkexample_git_dir
git checkout $SPARK_BRANCH_NAME
git fetch --all
git_hash=$(git rev-parse HEAD | tr -d '\n')
popd

echo "ok - tar zip maven and spark-xxx  source file, preparing for build/compile by rpmbuild"
pushd $workspace_rpm_dir
# Get a copy of the source code, and tar ball it
pushd $sparkexample_git_dir/../
tar --exclude .git --exclude .gitignore -cf $workspace_rpm_dir/sparkexample.tar sparkexample
popd

pushd $workspace_rpm_dir
tar -xf sparkexample.tar
if [ -d alti-sparkexample ] ; then
  rm -rf alti-sparkexample
fi
mv sparkexample alti-sparkexample
tar --exclude .git --exclude .gitignore -czf alti-sparkexample.tar.gz alti-sparkexample
popd

pushd $workspace_rpm_dir
rm -rf *.rpm
echo "ok - building apache maven RPM first"
if [ -f "$maven_settings" ] ; then
  mkdir -p  alti-maven-settings
  cp "$maven_settings" alti-maven-settings/
  tar -cvzf alti-maven-settings.tar.gz alti-maven-settings
  cp "$maven_settings_spec" .

  # Build alti-maven-settings RPM separately so it doesn't get exposed to spark's SRPM or any external trace
  alti_mock build --root=$BUILD_ROOT --spec=./alti-maven-settings.spec -S ./alti-maven-settings.tar.gz -D '_dummy dummy'
  if [ $? -ne "0" ] ; then
    echo "fail - alti-maven-settings SRPM build failed"
    popd
    cleanup_secrets $workspace_rpm_dir
    exit -95
  fi
fi

echo "ok - producing $SPARKEXAMPLE_PKG_NAME spec file"
cp $sparkexample_spec .
spec_name=$(basename $sparkexample_spec)
echo "ok - applying version number $SPARK_VERSION and other env variables to $(pwd)/$spec_name, the pattern delimiter is / here"
sed -i "s/SPARK_VERSION_REPLACE/$SPARK_VERSION/g" ./$spec_name
sed -i "s/SPARK_PLAINVERSION_REPLACE/$SPARK_PLAIN_VERSION/g" ./$spec_name
sed -i "s:CURRENT_WORKSPACE_REPLACE:$WORKSPACE:g" ./$spec_name
sed -i "s/HADOOP_VERSION_REPLACE/$HADOOP_VERSION/g" ./$spec_name
sed -i "s/HADOOP_BUILD_VERSION_REPLACE/$HADOOP_BUILD_VERSION/g" ./$spec_name
sed -i "s/HIVE_VERSION_REPLACE/$HIVE_VERSION/g" ./$spec_name
sed -i "s/SCALA_BUILD_VERSION_REPLACE/$SCALA_VERSION/g" ./$spec_name
sed -i "s/SPARKEXAMPLE_PKG_NAME/$SPARKEXAMPLE_PKG_NAME/g" ./$spec_name
sed -i "s/SPARK_GID/$SPARK_GID/g" ./$spec_name
sed -i "s/SPARK_UID/$SPARK_UID/g" ./$spec_name
sed -i "s/BUILD_TIME/$BUILD_TIME/g" ./$spec_name
sed -i "s/ALTISCALE_RELEASE/$ALTISCALE_RELEASE/g" ./$spec_name
sed -i "s/GITHASH_REV_RELEASE/$git_hash/g" ./$spec_name
sed -i "s/PRODUCTION_RELEASE/$PRODUCTION_RELEASE/g" ./$spec_name

alti_mock build --root=$BUILD_ROOT --spec=./$spec_name -S ./alti-sparkexample.tar.gz -D '_dummy dummy'
if [ $? -ne "0" ] ; then
  echo "fail - $spec_name SRPM build failed"
  popd
  cleanup_secrets $workspace_rpm_dir
  exit -95
fi
popd

echo "ok - build Completed successfully!"

exit 0













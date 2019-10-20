#!/bin/bash

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
rpm_file=""

if [ -f "$curr_dir/setup_env.sh" ]; then
  set -a
	source "$curr_dir/setup_env.sh"
  set +a
fi

WORKSPACE=${WORKSPACE:-"$curr_dir/workspace"}
sparkexample_git_dir=$WORKSPACE/sparkexample

env | sort

ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-"4.3.0"}
export RPM_NAME=`echo alti-spark-${SPARK_VERSION}-example`
export RPM_DESCRIPTION="Apache Spark Examples ${SPARK_VERSION}\n\n${DESCRIPTION}"

#####################
# Spark Example RPM #
#####################
echo "Packaging sparkexample rpm with name ${RPM_NAME} with version ${SPARK_VERSION}-${ALTISCALE_RELEASE}.${DATE_STRING}"

export RPM_BUILD_DIR="${INSTALL_DIR}/opt/alti-spark-${SPARK_VERSION}/test_spark"
# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${RPM_BUILD_DIR}"

rm -f "$RPM_BUILD_DIR/VERSION"
touch "$RPM_BUILD_DIR/VERSION"
echo "name=%{name}" >> "$RPM_BUILD_DIR/VERSION"
echo "version=%{_spark_version}" >> "$RPM_BUILD_DIR/VERSION"
echo "release=%{name}-%{release}" >> "$RPM_BUILD_DIR/VERSION"
echo "git_rev=%{_git_hash_release}" >> "$RPM_BUILD_DIR/VERSION"

pushd $sparkexample_git_dir
# deploy test suite and scripts
cp -rp target/*.jar $RPM_BUILD_DIR/
cp -rp * $RPM_BUILD_DIR/
popd

pushd ${RPM_DIR}
fpm --verbose \
--maintainer andrew.lee02@sap.com \
--vendor SAP \
--provides ${RPM_NAME} \
--description "$(printf "${RPM_DESCRIPTION}")" \
--replaces ${RPM_NAME} \
--url "${GITREPO}" \
--license "Apache License v2" \
--epoch 1 \
--rpm-os linux \
--architecture all \
--category "Development/Libraries" \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${SPARK_VERSION} \
--iteration ${ALTISCALE_RELEASE}.${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--rpm-auto-add-directories \
-C ${INSTALL_DIR} \
opt

if [ $? -ne 0 ] ; then
	echo "FATAL: sparkexample rpm build fail!"
	popd
	exit -1
fi
popd

exit 0

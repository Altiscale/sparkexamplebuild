sparkexamplebuild
==========

Init sparkexamplebuild wrapper repo for sparkexample repository official release.
This branch tracks the upstream starting from `branch-2.0-alti`. This is only available
after Spark 2.0+. To locate each Spark version and their examples, simply apply the
following naming convention.

- Spark x.y.0 => branch-x.y-alti
- Spark x.y.z => branch-x.y.z-alti

e.g. Spark 2.0.0 (first release for Major 2, Minor 2, and Patch 0) will align with
branch-2.0-alti. The Patch is ignored for the first major release. If there is a patch
afterward, such as 2.0.1, use `branch-2.0.1-alti`.

How to Install Spark Example RPM for this build
==========
```
# Install on Hadoop 2.7.1
yum install alti-spark-2.0.0-example

# or for future releases
# yum install alti-spark-2.0.1-example
# yum install alti-spark-2.1.0-example
# yum install alti-spark-2.1.1-example
```

The default location where the examples are installed are

```
/opt/alti-spark-x.y.z/test_spark
```

where x.y.z aligns with the version (e.g. 2.0.0/2.0.1/2.1.0/2.1.1, etc.)

Run Test Case
==========
Copy the folder from `$SPARK_HOME/test_spark` to somewhere on your workbench. 
We will use /tmp/ here for example. Run the command as the user you want to test. 
In Altiscale, `alti-test-01` is usually the user we use to test most test case. 
We will apply the same user here. You can also run the test case within $SPARK_HOME/test_spark/ 
directly since all files are copied to HDFS first or points to a writable temporarily directory.
Test case doesn't write to the current local direectory unless you forgot to specify
`hive-site.xml` which will launch a local SQL warehouse that may not have sufficient permission
to create a local warehouse under the runtime directory.

Login to remote workbench.
```
TARGET_SPARK_VERSION=2.0.0
ssh workbench_hostname
cp -rp /opt/alti-spark-${TARGET_SPARK_VERSION}/test_spark /tmp/test_spark-${TARGET_SPARK_VERSION}
pushd /tmp/test_spark-${TARGET_SPARK_VERSION}/
# For non-Kerberos cluster
./run_all_test.nokerberos.sh
# For kerberos enabled cluster
./run_all_test.kerberos.sh
popd
```

If you prefer (discouraged) to run it as root and delegate to alti-test-01 user, the following
command is sufficient. You must specify the SPARK_HOME and SPARK_CONF_DIR to pick up the
Spark 2.0.0 version, otherwise, the default version may be pointing to a different one such as
Spark 1.6.1 (`/opt/spark -> /opt/alti-spark-1.6.1`).

```
/bin/su - alti-test-01 -c "export SPARK_HOME=/opt/alti-spark-${TARGET_SPARK_VERSION}; export SPARK_CONF_DIR=/etc/alti-spark-${TARGET_SPARK_VERSION}; /tmp/test_spark-${TARGET_SPARK_VERSION}/test_spark_submit.sh"
```

The test should exit with 0 if everything completes correctly.

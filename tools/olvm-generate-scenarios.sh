#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TESTDIR=./scenarios/olvm


# The OLVM environment variables are either set manually by the local user
# or by the environment of a build job running the tests.
if [ -z "$OLVM_SERVER_URL" ]; then
	echo OLVM_SERVER_URL is not defined
	exit 1
fi

if [ -z "$OLVM_VIRTUAL_IP" ]; then
	echo OLVM_VIRTUAL_IP is not defined
	exit 1
fi

if [ -z "$OLVM_SUBNET_BASE" ]; then
	echo OLVM_SUBNET_BASE is not defined
	exit 1
fi

if [ -z "$OLVM_GATEWAY_IP" ]; then
	echo OLVM_GATEWAY_IP is not defined
	exit 1
fi



# Generate the OLVM configuration files
TEMPLATES=$(find "$TESTDIR" -name clusterConfigTemplate.yaml)

for TEMPLATE in $TEMPLATES; do
  CONFIG_FILE=${TEMPLATE/%clusterConfigTemplate.yaml}clusterConfig.yaml
  echo "Generating $CONFIG_FILE"
  envsubst < $TEMPLATE > $CONFIG_FILE
done

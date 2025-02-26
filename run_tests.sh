#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TESTDIR="$1"

TESTS=$(find "$TESTDIR" -mindepth 1 -maxdepth 1 -type d)

TEST_START=$(date +"%Y-%m-%d-%H:%m")
RESULTS="$(pwd)/$TEST_START"
mkdir -p "$RESULTS"
export GOCOVERDIR="$RESULTS"

for TEST_DIR in $TESTS; do
	export OCNE_DEFAULTS="$TEST_DIR/defaults.yaml"
	export CLUSTER_CONFIG="$TEST_DIR/clusterConfig.yaml"
	export CAPI_RESOURCES="$TEST_DIR/$(yq .clusterDefinition "$CLUSTER_CONFIG")"
	export MGMT_CONFIG="$TEST_DIR/managementConfig.yaml"
	export INFO="$TEST_DIR/info.yaml"
	export CASE_NAME=$(basename "$TEST_DIR")

	export PATH="$(pwd)/tools:$PATH"

	bats --setup-suite-file tests/setup/setup --trace --recursive tests/functional tests/upgrade
done

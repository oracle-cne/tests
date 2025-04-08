#! /bin/bash
#
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TESTDIR="$1"
PATTERN="$2"

TESTS=$(find "$TESTDIR" -mindepth 1 -maxdepth 1 -type d)

TEST_START=$(date +"%Y-%m-%d-%H:%m")
RESULTS="$(pwd)/$TEST_START"
mkdir -p "$RESULTS"
export GOCOVERDIR="$RESULTS"

export PATH="$(pwd)/tools:$PATH"

export MAX_KUBE_VERSION="1.31"

./tools/start-test-catalog.sh "$MAX_KUBE_VERSION"

for TEST_DIR in $TESTS; do
	if echo "$TEST_DIR" | grep -v "$PATTERN"; then
		echo "Skipping $TEST_DIR"
		continue
	fi
	echo "Running scenario $TEST_DIR"
	if [ -f "$TEST_DIR/defaults.yaml" ]; then
		export OCNE_DEFAULTS="$TEST_DIR/defaults.yaml"
	else
		unset OCNE_DEFAULTS
	fi
	if [ -f "$TEST_DIR/start.sh" ]; then
		export START_SCRIPT="$TEST_DIR/start.sh"
	else
		unset START_SCRIPT
	fi
	if [ -f "$TEST_DIR/delete.sh" ]; then
		export DELETE_SCRIPT="$TEST_DIR/delete.sh"
	else
		unset DELETE_SCRIPT
	fi
	export CLUSTER_CONFIG="$TEST_DIR/clusterConfig.yaml"
	export CAPI_RESOURCES="$TEST_DIR/$(yq .clusterDefinition "$CLUSTER_CONFIG")"
	export MGMT_CONFIG="$TEST_DIR/managementConfig.yaml"
	export INFO="$TEST_DIR/info.yaml"
	export CASE_NAME=$(basename "$TEST_DIR")

	bats --setup-suite-file tests/setup/setup --trace --recursive tests/cleanliness tests/functional tests/upgrade
done

./tools/stop-test-catalog.sh

#! /bin/bash
#
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TESTDIR=./scenarios/sanity
TEST_GROUPS="tests/functional tests/upgrade tests/scale"
PATTERN=
FORMAT=tap
RESULTS="$(pwd)/$(date +"%Y-%m-%d-%H:%m")"
USE_PODMAN=true
SUFFIX=tap
while true; do
	case "$1" in
	"") break;;
	-d | --dir ) TESTDIR="$2"; shift; shift ;;
	-p | --pattern ) PATTERN="$2"; shift; shift ;;
	-F | --format ) FORMAT="$2"; shift; shift ;;
	-r | --results ) RESULTS="$2"; shift; shift ;;
	-n | --no-podman ) USE_PODMAN="$2"; shift; shift ;;
	-t | --test-groups ) TEST_GROUPS="$2"; shift; shift ;;
	*) echo "$1 is not a valid parameter"; exit 1 ;;
	esac
done

TESTS=$(find "$TESTDIR" -mindepth 1 -maxdepth 1 -type d)

export GOCOVERDIR="$RESULTS/coverage_raw"
export MERGED_COVERAGE_DIR="$RESULTS/coverage_merged"
export COVERAGE="$RESULTS/coverage"
mkdir -p "$RESULTS"
mkdir -p "$GOCOVERDIR"
mkdir -p "$MERGED_COVERAGE_DIR"


export PATH="$(pwd)/tools:$PATH"

export MAX_KUBE_VERSION="1.32"

case "$FORMAT" in
	junit ) SUFFIX=xml;;
	tap* ) SUFFIX=tap;;
	* ) SUFFIX=out;;
esac

./tools/start-test-catalog.sh "$MAX_KUBE_VERSION" "$USE_PODMAN"


set -x
for TEST_DIR in $TESTS; do
	export INFO="$TEST_DIR/info.yaml"

	if echo "$TEST_DIR" | grep -v "$PATTERN"; then
		echo "Skipping $TEST_DIR"
		continue
	fi
	export SCALING_DEPLOYMENT=$(yq .scalingDeployment "$INFO")
	if [ "$SCALING_DEPLOYMENT" = "true" ] && [ "$CAPI_MODE" = "false" ]; then
		echo "Skipping $TEST_DIR" because CAPI_MODE is false and scalingDeployment is true
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
	export TEST_DIR_CURRENT="$TEST_DIR"
	export CLUSTER_CONFIG="$TEST_DIR/clusterConfig.yaml"
	export MGMT_CONFIG="$TEST_DIR/managementConfig.yaml"
	export CASE_NAME=$(basename "$TEST_DIR")

	bats --formatter "$FORMAT" --output "$RESULTS"  --setup-suite-file tests/setup/setup --trace --recursive $(echo $TEST_GROUPS) | tee "${RESULTS}/${CASE_NAME}.${SUFFIX}"
done

./tools/stop-test-catalog.sh "$USE_PODMAN"

go tool covdata merge -i="$GOCOVERDIR" -o="$MERGED_COVERAGE_DIR"
go tool covdata textfmt -i="$MERGED_COVERAGE_DIR" -o="$COVERAGE"

echo "Results Files"
find "$RESULTS" -type f 

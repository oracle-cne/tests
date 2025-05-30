#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

set -x
MAX_KUBE_VERSION="$1"
USE_PODMAN="$2"

MINOR_START=23
MINOR_END=$(echo "$MAX_KUBE_VERSION" | cut -d. -f2)

# Bump MINOR_END by 3 so that every version has three threever entry
MINOR_END=$((MINOR_END + 3))

TEMPLATE="templates/test-0.1.0"

rm -rf repo/*
rm -rf charts/*
rm -rf values/*
mkdir charts
mkdir repo
mkdir values

# Integer -> word
NUMBER=(zero one two three four five six seven eight nine)

VERSIONS=()
for minor in $(seq $MINOR_START $MINOR_END); do
	VERSIONS+=("1.$minor.0")
done

VERSIONS_LEN="${#VERSIONS[@]}"

# Make a bunch of applications with a range of three versions
# Supporting three versions references four versions.
# For example: ">= 1.26.0 < 1.29.0" supports 1.26, 1.27, and 1.28
RANGE=2
for i in $(seq $RANGE "$((VERSIONS_LEN - 2))"); do
	NAME=threevers
	VER="${VERSIONS[$i]}"
	CHART_DIR="charts/${NAME}-${VER}"
	cp -r "$TEMPLATE" "$CHART_DIR"
	yq -i ".name = \"${NAME}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".kubeVersion = \">= ${VERSIONS[$((i - RANGE))]} < ${VERSIONS[$((i + 1))]}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".appVersion = \"${VER}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".version = \"${VER}\"" "${CHART_DIR}/Chart.yaml"

	mkdir -p "values/${NAME}/${VER}"
	cp "${CHART_DIR}/values.yaml" "values/${NAME}/${VER}/values.yaml"
done

# Make a bunch of applications with single version
RANGE=0
for i in $(seq $RANGE "$((VERSIONS_LEN - 1))"); do
	NAME=onever
	VER="${VERSIONS[$i]}"
	CHART_DIR="charts/${NAME}-${VER}"
	cp -r "$TEMPLATE" "$CHART_DIR"
	yq -i ".name = \"${NAME}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".kubeVersion = \">= ${VERSIONS[$((i - RANGE))]} < ${VERSIONS[$((i + 1))]}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".appVersion = \"${VER}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".version = \"${VER}\"" "${CHART_DIR}/Chart.yaml"

	mkdir -p "values/${NAME}/${VER}"
	cp "${CHART_DIR}/values.yaml" "values/${NAME}/${VER}/values.yaml"
done

# Make a couple charts for installation and upgrade verification
for i in $(seq 0 2); do
	NAME=check
	VER="0.$i.0"
	CHART_DIR="charts/${NAME}-${VER}"
	cp -r "$TEMPLATE" "$CHART_DIR"
	yq -i ".name = \"${NAME}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".appVersion = \"${VER}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".version = \"${VER}\"" "${CHART_DIR}/Chart.yaml"
	yq -i ".configMapContents.testKey = \"$VER\"" "${CHART_DIR}/values.yaml"

	mkdir -p "values/${NAME}/${VER}"
	cp "${CHART_DIR}/values.yaml" "values/${NAME}/${VER}/values.yaml"
done

# Package them up
for chart in $(find ./charts -mindepth 1 -maxdepth 1 -type d); do
	helm package "$chart" -d repo
done

pushd repo
helm repo index .
popd #repo

if [ "$USE_PODMAN" = "true" ]; then
	podman build -t ocne/testcatalog:latest  .
fi

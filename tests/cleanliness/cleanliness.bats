#! /usr/bin/env bats
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

bats_require_minimum_version 1.5.0

@test "Validate images" {
	run -0 kubectl get node -o=jsonpath='{.items[*].metadata.name}'
	NODES="$output"

	for node in $NODES; do
		cat "$BATS_TEST_DIRNAME/check-base-layer.sh" | ocne cluster console --direct --node $node -- bash
	done
}

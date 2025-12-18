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

@test "Validate Kubernetes version" {
	run -0 kubectl get node -o=jsonpath='{.items[*].metadata.name}'
	NODES="$output"

	KUBE_VERSION="${TARGET_KUBE_VERSION}"
	if [ -z "$KUBE_VERSION" ]; then
		run -0 ocne cluster show -C "$CLUSTER_NAME" -f 'config.kubernetesVersion'
		KUBE_VERSION="$output"
	fi

	for node in $NODES; do
		run -0 kubectl get node $node -o=jsonpath='{.status.nodeInfo.kubeletVersion}'
		KUBELET_VERSION="$output"
		echo "Testing $KUBELET_VERSION against $KUBE_VERSION"
		echo "$KUBELET_VERSION" | grep -e "^v$KUBE_VERSION\\."

		run -0 kubectl get pods -n kube-system --field-selector spec.nodeName=${node},spec.serviceAccountName=kube-proxy -o jsonpath='{.items[].spec.containers[].image}'
		KUBE_PROXY_IMAGE="$output"
		run -0 bats_pipe kubectl get node $node -o jsonpath='{.status.images}' \| yq -r ".[] | select(.names | contains([\"${KUBE_PROXY_IMAGE}\"])) | .names[] | select(. != \"*sha*\" and . == \"*v${KUBE_VERSION}.*\")"
		KUBE_PROXY_IMAGE="$output"
		echo "Testing $KUBE_PROXY_IMAGE against $KUBE_VERSION"
		echo "$KUBE_PROXY_IMAGE" | grep -e ":v$KUBE_VERSION\\."
	done
}

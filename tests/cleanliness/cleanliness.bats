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
		echo "$KUBELET_VERSION" | grep -e "^v$KUBE_VERSION\\."

		run -0 kubectl get node $node -o=jsonpath='{.status.nodeInfo.kubeProxyVersion}'
		KUBE_PROXY_VERSION="$output"
		echo "$KUBE_PROXY_VERSION" | grep -e "^v$KUBE_VERSION\\."
	done
}

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

	run -0 ocne cluster show -C "$CLUSTER_NAME" -f 'config.kubernetesVersion'
	KUBE_VERSION="$output"

	for node in $NODES; do
		run -0 kubectl get node $node -o=jsonpath='{.status.nodeInfo.kubeletVersion}'
		KUBELET_VERSION="$output"
		echo "$KUBELET_VERSION" | grep -e "^v$KUBE_VERSION\\."

		# 1.33 k8s removes .status.nodeInfo.kubeProxyVersion this information
		run -0 kubectl get po -n kube-system | grep kube-proxy | tail -n1 | awk '{print $1}'
		KUBE_PROXY_POD="$output"
		run -0 kubectl exec -it $KUBE_PROXY_POD -n kube-system -- /usr/local/bin/kube-proxy --version | awk '{print $2}'
		KUBE_PROXY_VERSION="$output"
		echo "$KUBE_PROXY_VERSION" | grep -e "^v$KUBE_VERSION\\."
	done
}

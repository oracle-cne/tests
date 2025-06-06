#! /usr/bin/env bats
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=CLUSTER, CLUSTER_CLUSTER

@test "Sanity Check" {
	basic_k8s_test.sh
}

@test "Verify UI Service" {
	kubectl -n ocne-system get service ui
}

@test "Verify Catalog Service" {
	kubectl -n ocne-system get service ocne-catalog
}

@test "Verify Flannel" {
	kubectl -n kube-flannel get daemonset kube-flannel-ds
}

@test "Verify Cluster List" {
	run -0 ocne cluster ls
	grep "^$CLUSTER_NAME\$" <(echo "$output")
	run -0 ocne cluster list
	grep "^$CLUSTER_NAME\$" <(echo "$output")
}

@test "Verify Cluster Info" {
	run kubectl get node -o=jsonpath='{.items[0].metadata.name}'
	[ "$status" -eq 0 ]
	NODE="$output"

	run ocne cluster info
	[ "$status" -eq 0 ]
	echo "$output" | grep 'Registry and tag for ostree patch images'

	run ocne cluster info --nodes $NODE
	[ "$status" -eq 0 ]
	echo "$output" | grep 'Registry and tag for ostree patch images'

	run ocne cluster info --skip-nodes
	[ "$status" -eq 0 ]
	echo "$output" | grep -v 'Registry and tag for ostree patch images'
}

@test "Verify Cluster Show" {
	run -0 ocne cluster show -C $CLUSTER_NAME
	[ "$output" = "$KUBECONFIG" ]

	ocne cluster show -C $CLUSTER_NAME -a
}

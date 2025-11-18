#! /usr/bin/env bats
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

doSkip() {
	TGT="$1"

	verList=$((echo "$TGT"; echo "$KUBE_VERSION") | sort -r -V)
	if [ "$(echo "$verList" | head -1)" = "$KUBE_VERSION" ]; then
		skip "$KUBE_VERSION is later than $TGT"
	fi
}

waitFor() {
	KIND="$1"
	NAMESPACE="$2"
	NAME="$3"

	# Give the controllers a bit to start their thing
	sleep 30

	# Wait for version
	echo "Wait for $KIND named $NAME in namespace $NAMESPACE"
	for i in $(seq 1 100); do
		run -0 kubectl -n "$NAMESPACE" get "$KIND" "$NAME" -o yaml
		YAML="$output"

		run -0 yq '.status.replicas' <(echo "$YAML")
		REPLICAS="$output"

		run -0 yq '.status.readyReplicas' <(echo "$YAML")
		READY_REPLICAS="$output"

		run -0 yq '.status.updatedReplicas' <(echo "$YAML")
		UPDATED_REPLICAS="$output"

		if [ "$REPLICAS" = "$READY_REPLICAS" ] && [ "$REPLICAS" = "$UPDATED_REPLICAS" ]; then
			return 0
		fi

		sleep 9
	done

	false
}

waitForNoNodesSchedulingDisabled() {
	echo "Wait for no nodes to be in SchedulingDisabled state"
	for i in $(seq 1 30); do
			kubectl get nodes | grep -qv SchedulingDisabled
			if [ $? -eq 0 ]; then
					return 0
			fi
			sleep 8
	done

	false
}

doUpgrade() {
	TGT="$1"
	doSkip "$TGT"

	case "$UPDATE_MODE" in
	capi ) doCapiUpgrade "$TGT" ;;
	node ) doNodeUpgrade "$TGT" ;;
	*) false ;;
	esac
}

doNodeUpgrade() {
	TGT="$1"

	run -0 ocne cluster stage --version "$TGT"

	run -0 kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
	NODES="$output"
	NUM_NODES=$(echo -n "$NODES" | wc -l)

	run -0 kubectl get nodes -l 'node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
	CP_NODES="$output"

	run -0 kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
	WORKER_NODES="$output"

	# Wait for updates to be available
	for i in $(seq 1 100); do
		run -0 kubectl get node -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.annotations}{"\n"}{end}'
		echo "node annotations are are $output"

		#run -0 kubectl get node -o jsonpath='{range .items[?(@.metadata.annotations.ocne\.oracle\.com/update-available=="true")]}{.metadata.name}{"\n"}{end}'
		run bats_pipe ocne cluster info \| grep -e 'control plane.*v1.*true$' -e 'worker.*v1.*true$'
		UPDATES="$output"
		NUM_UPDATES=$(echo -n "$UPDATES" | wc -l)
		echo "updates: $UPDATES"
		echo "$NUM_UPDATES" = "$NUM_NODES"

		if [ "$NUM_UPDATES" = "$NUM_NODES" ]; then
			break
		fi
		sleep 10
	done

	# Do control plane updates
	for cpn in $CP_NODES; do
		run ocne node update --node "$cpn" --delete-emptydir-data

		# Sometimes the command terminates early with a websocket failure.
		# Tolerate it until it is fixed.  The upgrade continues and completes.
		if [ "$status" != 0 ]; then
			echo "$output"
			run -0 bats_pipe echo "$output" \| grep "unexpected EOF"
		fi

		# It can take kubelet a bit to report itself at a new version.
		# Let that shake out
		for i in $(seq 1 100); do
			run bats_pipe kubectl get node "$cpn" -o=jsonpath='{.status.nodeInfo.kubeletVersion}' \| grep "^v$TGT"
			if [ "$status" = 0 ]; then
				break
			fi
			sleep 11
		done

		# Sometimes the NoSchedule taint gets stuck if the kube-apiserver
		# connection hiccups at the wrong time.  Clear it.
		kubectl uncordon "$cpn"
	done

	# Do worker nodes
	for wn in $WORKER_NODES; do
		run ocne node update --node "$wn" --delete-emptydir-data
		# Sometimes the command terminates early with a websocket failure.
		# Tolerate it until it is fixed.  The upgrade continues and completes.
		if [ "$status" != 0 ]; then
			echo "$output"
			run -0 bats_pipe echo "$output" \| grep "unexpected EOF"
		fi

		# It can take kubelet a bit to report itself at a new version.
		# Let that shake out
		for i in $(seq 1 100); do
			run bats_pipe kubectl get node "$wn" -o=jsonpath='{.status.nodeInfo.kubeletVersion}' \| grep "^v$TGT"
			if [ "$status" = 0 ]; then
				break
			fi
			sleep 12
		done
	done

	kubectl wait --for=condition=Ready nodes --all --timeout=600s
}

doCapiUpgrade() {
	TGT="$1"

	export KUBECONFIG="$MGMT_KUBECONFIG"
	case "$PROVIDER" in
	oci ) stageOci "$TGT" ;;
	olvm ) stageOlvm "$TGT" ;;
	esac

	# get patches
	echo "$STAGE_OUT"
	run -0 bats_pipe echo "$STAGE_OUT" \| grep -e 'kubectl patch -n [a-zA-Z0-9-]* kubeadmcontrolplane *'
	cpPatch="$output"
	echo "$cpPatch"

	run -0 bats_pipe echo "$STAGE_OUT" \| grep -e 'kubectl patch -n [a-zA-Z0-9-]* machinedeployment *'
	workerPatches="$output"
	echo "$workerPatches"

	# upgrade control plane nodes
	echo $cpPatch
	echo "$cpPatch" | bash

	run -0 yq '.kind, .metadata.name, .metadata.namespace' "$CAPI_RESOURCES"
	KINDS_AND_NAMES="$output"
	run -0 grep KubeadmControlPlane -A 2 <(echo "$KINDS_AND_NAMES")

	CP_NAME="${lines[1]}"
	CP_NAMESPACE="${lines[2]}"
	waitFor kubeadmcontrolplane "$CP_NAMESPACE" "$CP_NAME"
	waitForNoNodesSchedulingDisabled

	# Validate Kubernetes Version
	export KUBECONFIG="$TARGET_KUBECONFIG"
	run -0 kubectl version -o yaml
	VERSION_INFO="$output"
	run -0 bats_pipe echo "$VERSION_INFO" \| yq .serverVersion.major
	MAJOR="$output"
	run -0 bats_pipe echo "$VERSION_INFO" \| yq .serverVersion.minor
	MINOR="$output"

	echo "$TGT" "$MAJOR.$MINOR"
	[ "$TGT" = "$MAJOR.$MINOR" ]

	run -0 kubectl get node -l node-role.kubernetes.io/control-plane -o=jsonpath='{.items[*].status.nodeInfo.kubeletVersion} '
	CP_VERSIONS="$output"
	VERSION_LINES=$(echo "$CP_VERSIONS" | tr ' ' '\n')

	grep "^v$TGT" <(echo "$VERSION_LINES")

	[ "${#lines[@]}" = $(echo "$VERSION_LINES" | wc -l) ]

	# upgrade worker nodes, assuming one MachineDeployment
	export KUBECONFIG="$MGMT_KUBECONFIG"
	echo "$workerPatches" | bash

	run -0 grep MachineDeployment -A 2 <(echo "$KINDS_AND_NAMES")
	MD_NAME="${lines[1]}"
	MD_NAMESPACE="${lines[2]}"
	waitFor machinedeployment "$MD_NAMESPACE" "$MD_NAME"
	waitForNoNodesSchedulingDisabled

	# All nodes should be updated, and all other nodes
	# destroyed.  Give it a bit for the controllers to
	# shake out
	export KUBECONFIG="$TARGET_KUBECONFIG"
	for i in $(seq 1 100); do
		run -0 kubectl get --no-headers node
		NODES="$output"
		NUM_NODES=$(echo "$NODES" | wc -l)
		echo "$NUM_NODES  Nodes: $NODES"

		run -0 kubectl get node -o=jsonpath='{.items[*].status.nodeInfo.kubeletVersion} '
		NODE_VERSIONS="$output"
		VERSION_LINES=$(echo "$NODE_VERSIONS" | tr ' ' '\n')
		NUM_VERSION_LINES=$(echo "$VERSION_LINES" | wc -l)
		echo "$NUM_VERSION_LINES Version Lines: $VERSION_LINES"

		run -0 bats_pipe echo "$VERSION_LINES" \| grep "^v$TGT"
		NEW_VERSION_LINES="$output"
		NUM_NEW_NODES=$(echo "$NEW_VERSION_LINES" | wc -l)
		echo "$NUM_NEW_NODES New nodes: $NEW_VERSION"
		if [ "$NUM_NEW_NODES" = "$NUM_NODES" ]; then
			export KUBECONFIG="$MGMT_KUBECONFIG"
			return 0
		fi
		sleep 13
	done
	export KUBECONFIG="$MGMT_KUBECONFIG"
	false
}

stageOci() {
	TGT="$1"
	export KUBECONFIG="$MGMT_KUBECONFIG"

	run -0 ocne cluster stage --version "$TGT" -c "$CLUSTER_CONFIG"
	export STAGE_OUT="$output"
}

stageOlvm() {
	TGT="$1"
	export KUBECONFIG="$MGMT_KUBECONFIG"

	case "$TGT" in
	1.30 ) TEMPLATE="$OLVM_VM_TEMPLATE_1_30" ;;
	1.31 ) TEMPLATE="$OLVM_VM_TEMPLATE_1_31" ;;
	*) echo "$TGT is not a valid upgrade target for OLVM"; exit 1 ;;
	esac

	echo "Update OLVM to use template $TEMPLATE"
	yq ".providers.olvm.controlPlaneMachine.vmTemplateName = \"${TEMPLATE}\", .providers.olvm.workerMachine.vmTemplateName = \"${TEMPLATE}\"" < "$CLUSTER_CONFIG" > "$CLUSTER_CONFIG"-stage
	run -0 ocne cluster stage --version "$TGT" -c "$CLUSTER_CONFIG"-stage
	export STAGE_OUT="$output"
	echo "Updated config for the OLVM cluster"
	ocne cluster show -C $(yq -e .name $CLUSTER_CONFIG) -f "config.providers.olvm"
}

@test "Basic Kubernetes Tests for 1.26" {
	doSkip 1.26
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.27" {
	doUpgrade 1.27
}

@test "Basic Kubernetes Tests for 1.27" {
	doSkip 1.27
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.28" {
	doUpgrade 1.28
}

@test "Basic Kubernetes Tests for 1.28" {
	doSkip 1.28
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.29" {
	doUpgrade 1.29
}

@test "Basic Kubernetes Tests for 1.29" {
	doSkip 1.29
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.30" {
	doUpgrade 1.30
}

@test "Basic Kubernetes Tests for 1.30" {
	doSkip 1.30
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.31" {
	doUpgrade 1.31
}

@test "Basic Kubernetes Tests for 1.31" {
	doSkip 1.31
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

@test "Upgrade to 1.32" {
	doUpgrade 1.32
}

@test "Basic Kubernetes Tests for 1.32" {
	doSkip 1.32
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}
@test "Upgrade to 1.33" {
	doUpgrade 1.33
}

@test "Basic Kubernetes Tests for 1.33" {
	doSkip 1.33
	export KUBECONFIG="$TARGET_KUBECONFIG"
	basic_k8s_test.sh
}

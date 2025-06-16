#! /usr/bin/env bats
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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

		run -0 yq '.spec.replicas' <(echo "$YAML")
		REPLICAS="$output"

		run -0 yq '.status.readyReplicas' <(echo "$YAML")
		READY_REPLICAS="$output"

		run -0 yq '.status.updatedReplicas' <(echo "$YAML")
		UPDATED_REPLICAS="$output"

		if [ "$REPLICAS" = "$READY_REPLICAS" ] && [ "$REPLICAS" = "$UPDATED_REPLICAS" ]; then
			return 0
		fi

		sleep 12
	done

	false
}

scaleCapiControlPlane() {
    export KUBECONFIG="$MGMT_KUBECONFIG"

    run -0 yq '.kind, .metadata.name, .metadata.namespace' "$CAPI_RESOURCES"
    KINDS_AND_NAMES="$output"
	run -0 grep KubeadmControlPlane -A 2 <(echo "$KINDS_AND_NAMES")
	CP_NAME="${lines[1]}"
	CP_NAMESPACE="${lines[2]}"

    kubectl scale kubeadmcontrolplane $CP_NAME --namespace $CP_NAMESPACE --replicas=3
	waitFor kubeadmcontrolplane "$CP_NAMESPACE" "$CP_NAME"

    kubectl scale kubeadmcontrolplane $CP_NAME --namespace $CP_NAMESPACE --replicas=1
	waitFor kubeadmcontrolplane "$CP_NAMESPACE" "$CP_NAME"
}

scaleCapiWorker() {
    export KUBECONFIG="$MGMT_KUBECONFIG"

    run -0 yq '.kind, .metadata.name, .metadata.namespace' "$CAPI_RESOURCES"
    KINDS_AND_NAMES="$output"
	run -0 grep MachineDeployment -A 2 <(echo "$KINDS_AND_NAMES")
	MD_NAME="${lines[1]}"
	MD_NAMESPACE="${lines[2]}"

    kubectl scale machinedeployment $MD_NAME --namespace $MD_NAMESPACE --replicas=3
	waitFor machinedeployment "$MD_NAMESPACE" "$MD_NAME"

    kubectl scale machinedeployment $MD_NAME --namespace $MD_NAMESPACE --replicas=1
	waitFor machinedeployment "$MD_NAMESPACE" "$MD_NAME"
}


@test "Scale Workers" {
    case "$PROVIDER" in
    olvm ) scaleCapiWorker ;;
	*) false ;;
    esac
}

@test "Scale ControlPlane" {
    case "$PROVIDER" in
    olvm ) scaleCapiControlPlane ;;
	*) false ;;
    esac
}

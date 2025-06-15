#! /bin/bash
set -e
set -x

EXCEPTION='container-registry.oracle.com/olcne/nginx:1.17.7-1 container-registry.oracle.com/olcne/pause:3.10 container-registry.oracle.com/olcne/pause:3.9 container-registry.oracle.com/olcne/ovirt-csi-driver:v4.20.0 container-registry.oracle.com/olcne/csi-node-driver-registrar:v2.13.0 container-registry.oracle.com/olcne/csi-attacher:v4.8.1 container-registry.oracle.com/olcne/csi-resizer:v1.13.2 container-registry.oracle.com/olcne/csi-provisioner:v5.2.0 container-registry.oracle.com/olcne/livenessprobe:v2.15.0'

BASE_INSPECT="$(podman image inspect container-registry.oracle.com/os/oraclelinux:8)"
BASE_LAYER=$(echo "$BASE_INSPECT" | yq '.[].RootFS.Layers[0]')

IMAGES=$(podman images --format='{{.Repository}}:{{.Tag}}')

for img in $IMAGES; do
	[ "$(podman image list --format '{{.ReadOnly}}' $img | uniq)" = "true" ]
	INSPECT="$(podman image inspect $img)"

	if echo "${EXCEPTION}" | grep -q -e "$img"; then
		echo "$INSPECT" | yq -e '.[].RootFS.Layers | length == 1'
	else
		echo "$INSPECT" | yq -e '.[].RootFS.Layers | length <= 2'
		echo "$INSPECT" | yq -e ".[].RootFS.Layers[0] | (. == \"${BASE_LAYER}\")"
	fi
done

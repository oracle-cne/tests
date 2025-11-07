#! /bin/bash
set -e
set -x

EXCEPTION='container-registry.oracle.com/olcne/nginx container-registry.oracle.com/olcne/pause:3.10 container-registry.oracle.com/olcne/pause:3.9'

BASE_INSPECT="$(podman image inspect container-registry.oracle.com/os/oraclelinux:8)"
BASE_LAYER=$(echo "$BASE_INSPECT" | yq '.[].RootFS.Layers[0]')

IMAGES=$(podman images --format='{{.Repository}}:{{.Tag}}')

for img in $IMAGES; do
	[ "$(podman image list --format '{{.ReadOnly}}' $img | uniq)" = "true" ]
	INSPECT="$(podman image inspect $img)"

	IS_SINGLE_LAYER=false

	for except in ${EXCEPTION}; do
		if echo "$img" | grep -q -e "$except"; then
			IS_SINGLE_LAYER=true
			break
		fi
	done

	if [ "$IS_SINGLE_LAYER" == "true" ]; then
		echo "$INSPECT" | yq -e '.[].RootFS.Layers | length == 1'
	else
		echo "$INSPECT" | yq -e '.[].RootFS.Layers | length <= 2'
		echo "$INSPECT" | yq -e ".[].RootFS.Layers[0] | (. == \"${BASE_LAYER}\")"
	fi
done

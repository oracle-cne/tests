#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/env.sh"

set -x

create_node() {
	MODE="$1"
	NAME="$2"

	cat > "${NAME}.but" << EOF
variant: fcos
version: 1.5.0
storage:
  files:
  - path: /etc/hostname
    contents:
      inline: ${NAME}
EOF
	yq ".extraIgnition = \"${NAME}.but\"" < "$CLUSTER_CONFIG" > "${NAME}.cc.yaml"
	ocne cluster "$MODE" -c "${NAME}.cc.yaml" > "${NAME}.ign"
	create_domain "$NAME" "${NAME}.ign"
}

# Generate the intial ignition
create_node start "${CLUSTER_NAME}-control-plane"
export KUBECONFIG=$(ocne cluster show -C "$CLUSTER_NAME")


# Sleep for a bit to let networking shake out
sleep 60s

# Install the default applications
ocne cluster start -c "$CLUSTER_CONFIG" --auto-start-ui=false

# join some worker nodes
create_node join "${CLUSTER_NAME}-worker-1"
create_node join "${CLUSTER_NAME}-worker-2"
create_node join "${CLUSTER_NAME}-worker-3"

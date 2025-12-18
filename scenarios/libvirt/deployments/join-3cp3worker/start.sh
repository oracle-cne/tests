#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -x

export OLDCNE=/usr/bin/ocne

TO_CC="${SCRIPT_DIR}/clusterConfig.yaml"
FROM_CC="${SCRIPT_DIR}/clusterConfig-from.yaml"
TO=$(yq '.name' "$TO_CC")
FROM=$(yq '.name' "$FROM_CC")

# Create the 'to' cluster
ocne cluster start -c "$TO_CC" --auto-start-ui false

# create the 'from' cluster
${OLDCNE} cluster start -c "$FROM_CC" --auto-start-ui false

sleep 120

# Stitch them together.  Start with worker nodes b/c migrating the control
# plane node will obviously break access to said workers.
export TO_KUBECONFIG=$(ocne cluster show -C "$TO")
export FROM_KUBECONFIG=$(ocne cluster show -C "$FROM")

export KUBECONFIG="$FROM_KUBECONFIG"

# Get node names
NODES=$(kubectl get node -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')

for node in $(echo "$NODES" | grep -e '-worker-'); do
	ocne cluster join --node "$node" --kubeconfig "$FROM_KUBECONFIG" --destination "$TO_KUBECONFIG"
done

for node in $(echo "$NODES" | grep -e '-control-plane-'); do
	ocne cluster join --node "$node" --role-control-plane --kubeconfig "$FROM_KUBECONFIG" --destination "$TO_KUBECONFIG" --log-level debug
done

# Let everything shake out for a bit
sleep 60

export KUBECONFIG="$TO_KUBECONFIG"

NODES=$(kubectl get node -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')
echo "$NODES"

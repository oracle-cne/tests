#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/env.sh"

set -x

ocne cluster delete -c "$CLUSTER_CONFIG"

for dom in $(sudo virsh list --all --name | grep "^${CLUSTER_NAME}"); do
	sudo virsh destroy "$dom"
	sudo virsh undefine --nvram "$dom"
	sudo rm "${POOL_PATH}/${dom}.qcow2"
	rm "${dom}.xml"
	rm "${dom}.ign"
	rm "${dom}.but"
	rm "${dom}.cc.yaml"
done

sudo virsh pool-refresh images

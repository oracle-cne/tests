#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -x

TO_CC="${SCRIPT_DIR}/clusterConfig.yaml"
FROM_CC="${SCRIPT_DIR}/clusterConfig-from.yaml"
TO=$(yq '.name' "$TO_CC")
FROM=$(yq '.name' "$FROM_CC")

# Create the 'to' cluster
ocne cluster delete -c "$TO_CC"

# create the 'from' cluster
ocne cluster delete -c "$FROM_CC"


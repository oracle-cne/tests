#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
if [ -z "$1" ]; then
	exit 0
fi
oci iam compartment delete --compartment-id "$1"

#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

USE_PODMAN="$1"

if [ "$USE_PODMAN" = "true" ]; then
	podman stop ocnetestcatalog
else
	pushd fixtures/catalog
	kill $(cat nginx.pid)
	popd # fixtures/catalog
fi

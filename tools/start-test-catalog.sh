#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

USE_PODMAN="$2"

pushd fixtures/catalog
sh generate.sh "$1" "$USE_PODMAN"
popd # fixtures/catalog

if [ "$USE_PODMAN" = "true" ]; then
	podman run -d --name ocnetestcatalog --rm -p 8080:80 ocne/testcatalog:latest
else
	pushd fixtures/catalog
	nginx -p `pwd` -c ./nginx-local.conf -e /dev/null
	popd # fixtures/catalog
fi

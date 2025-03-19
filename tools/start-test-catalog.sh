#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

pushd fixtures/catalog
sh generate.sh "$1"
popd # fixtures/catalog

podman run -d --name ocnetestcatalog --rm -p 8080:80 ocne/testcatalog:latest

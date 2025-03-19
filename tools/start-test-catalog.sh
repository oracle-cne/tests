#! /bin/bash

pushd fixtures/catalog
sh generate.sh "$1"
popd # fixtures/catalog

podman run -d --name ocnetestcatalog --rm -p 8080:80 ocne/testcatalog:latest

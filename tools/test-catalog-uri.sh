#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export IFACE=$(ip route | grep default | head -1 | grep -o 'dev [a-z0-9]*' | cut -d' ' -f2)
export IP_ADDR=$(ip addr show dev $IFACE | grep -o 'inet [0-9.]*' | cut -d' ' -f 2)
echo http://$IP_ADDR:8080

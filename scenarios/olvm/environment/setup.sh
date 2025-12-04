#! /bin/bash
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

TESTDIR=./scenarios/olvm


# The OLVM environment variables are either set manually by the local user
# or by the environment of a build job running the tests.
if [ -z "$OLVM_CLUSTER_NAMESPACE" ]; then
	echo OLVM_CLUSTER_NAMESPACE is not defined
	exit 1
fi

if [ -z "$OLVM_SERVER_URL" ]; then
	echo OLVM_SERVER_URL is not defined
	exit 1
fi

if [ -z "$OLVM_VIRTUAL_IP" ]; then
	echo OLVM_VIRTUAL_IP is not defined
	exit 1
fi

if [ -z "$OLVM_SUBNET" ]; then
	echo OLVM_SUBNET is not defined
	exit 1
fi

if [ -z "$OLVM_STARTING_IPV4_ADDRESS_CP" ]; then
	echo OLVM_STARTING_IPV4_ADDRESS_CP is not defined
	exit 1
fi

if [ -z "$OLVM_ENDING_IPV4_ADDRESS_CP" ]; then
	echo OLVM_ENDING_IPV4_ADDRESS_CP is not defined
	exit 1
fi

if [ -z "$OLVM_STARTING_IPV4_ADDRESS_W" ]; then
	echo OLVM_STARTING_IPV4_ADDRESS_W is not defined
	exit 1
fi

if [ -z "$OLVM_ENDING_IPV4_ADDRESS_W" ]; then
	echo OLVM_ENDING_IPV4_ADDRESS_W is not defined
	exit 1
fi

if [ -z "$OLVM_DATACENTER_NAME" ]; then
	export OLVM_DATACENTER_NAME=default
	echo Defaulting OLVM_DATACENTER_NAME to "default"
fi

if [ -z "$OLVM_STORAGE_DOMAIN_NAME" ]; then
	echo OLVM_STORAGE_DOMAIN_NAME is not defined
	exit 1
fi

if [ -z "$OCNE_OCK_DISK_NAME_1_31" ]; then
	echo OCNE_OCK_DISK_NAME_1_31 is not defined
	exit 1
fi

if [ -z "$OCNE_OCK_DISK_NAME_1_32" ]; then
	echo OCNE_OCK_DISK_NAME_1_32 is not defined
	exit 1
fi

if [ -z "$OLVM_NETWORK_NAME" ]; then
	export OLVM_NETWORK_NAME=vlan
	echo Defaulting OLVM_NETWORK_NAME to "vlan"
fi

if [ -z "$OLVM_NETWORK_GATEWAY_IP" ]; then
	echo OLVM_NETWORK_GATEWAY_IP is not defined
	exit 1
fi

if [ -z "$OLVM_NETWORK_VNIC_NAME" ]; then
	export OLVM_NETWORK_VNIC_NAME=nic-1
	echo Defaulting OLVM_NETWORK_VNIC_NAME to "nic-1"
fi

if [ -z "$OLVM_NETWORK_INTERFACE" ]; then
	export OLVM_NETWORK_INTERFACE=enp1s0
	echo Defaulting OLVM_NETWORK_INTERFACE to "enp1s0"
fi

if [ -z "$OLVM_NETWORK_INTERFACE_TYPE" ]; then
	export OLVM_NETWORK_INTERFACE_TYPE=virtio
	echo Defaulting OLVM_NETWORK_INTERFACE_TYPE to "virtio"
fi

if [ -z "$OLVM_CA_CERT_PATH" ]; then
	echo OLVM_CA_CERT_PATH is not defined
	exit 1
fi

if [ -z "$OLVM_VM_TEMPLATE_1_31" ]; then
	echo OLVM_VM_TEMPLATE_1_31 is not defined
	exit 1
fi

if [ -z "$OLVM_VM_TEMPLATE_1_32" ]; then
	echo OLVM_VM_TEMPLATE_1_32 is not defined
	exit 1
fi

if [ -z "$OLVM_VM_TEMPLATE_1_33" ]; then
	echo OLVM_VM_TEMPLATE_1_33 is not defined
	exit 1
fi

if [ -z "$NAMESERVER_IP" ]; then
	echo NAMESERVER_IP is not defined
	exit 1
fi

if [ -z "$OLVM_HTTPS_PROXY" ]; then
	echo OLVM_HTTPS_PROXY is not defined
	exit 1
fi

if [ -z "$OLVM_HTTP_PROXY" ]; then
	echo OLVM_HTTP_PROXY is not defined
	exit 1
fi

if [ -z "$OLVM_NO_PROXY" ]; then
	echo OLVM_NO_PROXY is not defined
	exit 1
fi

if [ -z "$OCNE_OLVM_USERNAME" ]; then
	echo OCNE_OLVM_USERNAME is not defined
	exit 1
fi

if [ -z "$OCNE_OLVM_PASSWORD" ]; then
	echo OCNE_OLVM_PASSWORD is not defined
	exit 1
fi

if [ -z "$OCNE_OLVM_SCOPE" ]; then
	echo OCNE_OLVM_SCOPE is not defined
	exit 1
fi

# Generate the OLVM configuration files
TEMPLATES=$(find "$TESTDIR" -name clusterConfigTemplate.yaml)

for TEMPLATE in $TEMPLATES; do
	CONFIG_FILE=${TEMPLATE/%clusterConfigTemplate.yaml}clusterConfig.yaml
	echo "Generating $CONFIG_FILE"
	envsubst < "$TEMPLATE" > "$CONFIG_FILE"
done

#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sudo virsh net-define "$SCRIPT_DIR/dualstack.yaml"
sudo virsh net-start dualstack

sudo virsh net-define "$SCRIPT_DIR/ipv6.yaml"
sudo virsh net-start ipv6only

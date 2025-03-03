#! /bin/bash

sudo virsh net-destroy dualstack
sudo virsh net-undefine dualstack

sudo virsh net-destroy ipv6only
sudo virsh net-undefine ipv6only

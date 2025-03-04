#! /bin/bash

sudo virsh net-destroy dualstack
sudo virsh net-undefine dualstack

sudo virsh net-destroy ipv6only
sudo virsh net-undefine ipv6only

sudo virsh net-destroy nodhcp
sudo virsh net-undefine nodhcp

sudo virsh net-destroy nodhcp-dualstack
sudo virsh net-undefine nodhcp-dualstack

sudo virsh net-destroy nodhcp-ipv6only
sudo virsh net-undefine nodhcp-ipv6only

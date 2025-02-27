#! /bin/bash

sudo virsh net-define dualstack.yaml
sudo virsh net-define ipv6.yaml
sudo virsh start dualstack
sudo virsh start ipv6only

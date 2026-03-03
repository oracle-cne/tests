#! /usr/bin/env bats
#
# Copyright (c) 2026, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=CLUSTER,CLUSTER_VSPHERE

setup() {
  # Minimal common vars; adjust if the harness exports cluster/env defaults
  export CLUSTER_NAME="vsphere-test"
  export KUBECONFIG="${BATS_TMPDIR}/kubeconfig"
}

teardown() {
  # Nothing to cleanup; no clusters are created in these validation-only tests
  true
}

# Helper to run ocne cluster template for vsphere with injected yaml snippet
template_vsphere() {
  local yaml_snippet="$1"
  local tmpcfg
  tmpcfg=$(mktemp)
  cat >"${tmpcfg}" <<EOF
clusterName: ${CLUSTER_NAME}
provider: vsphere
providers:
  vsphere:
${yaml_snippet}
controlPlaneNodes: 1
workerNodes: 1
kubernetesVersion: v1.29.0
kubeApiServerBindPort: 6443
podSubnet: 10.244.0.0/16
serviceSubnet: 10.96.0.0/12
EOF
  ocne cluster template -c "${tmpcfg}"
  rm -f "${tmpcfg}"
}

@test "vsphere validation: fails when controlPlaneNodes is even" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    username: user
    password: pass
    namespace: ns
    controlPlaneEndpoint: 1.2.3.4
controlPlaneNodes: 2"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "odd"
}

@test "vsphere validation: fails when kubernetesVersion missing" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    username: user
    password: pass
    namespace: ns
    controlPlaneEndpoint: 1.2.3.4
kubeApiServerBindPort: 6443
podSubnet: 10.244.0.0/16
serviceSubnet: 10.96.0.0/12"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "kubernetesVersion is required"
}

@test "vsphere validation: fails when kubeApiServerBindPort is 0" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    username: user
    password: pass
    namespace: ns
    controlPlaneEndpoint: 1.2.3.4
kubernetesVersion: v1.29.0
kubeApiServerBindPort: 0"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "kubeApiServerBindPort"
}

@test "vsphere validation: fails when namespace missing" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    username: user
    password: pass
    controlPlaneEndpoint: 1.2.3.4"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "namespace"
}

@test "vsphere validation: fails when required fields missing" {
  # Missing several required fields (network/datastore/resourcePool/template)
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    namespace: ns
    username: user
    password: pass
    controlPlaneEndpoint: 1.2.3.4"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "requires server, datacenter, network, datastore, resourcePool, template"
}

@test "vsphere validation: fails when credentials missing" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    namespace: ns
    controlPlaneEndpoint: 1.2.3.4"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "requires credentials"
}

@test "vsphere validation: fails when controlPlaneEndpoint missing" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    namespace: ns
    username: user
    password: pass"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "controlPlaneEndpoint"
}

@test "vsphere validation: succeeds with minimal required fields" {
  run template_vsphere "    server: vcenter.local
    datacenter: dc
    network: net
    datastore: ds
    resourcePool: rp
    folder: folder
    template: tpl
    namespace: ns
    username: user
    password: pass
    controlPlaneEndpoint: 1.2.3.4"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "VSphereCluster"
  echo "$output" | grep -q "KubeadmControlPlane"
}

#! /usr/bin/env bats
#
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=CATALOG

setup_file() {
	ocne catalog add -u $(test-catalog-uri.sh) -N apptestcatalog
}

teardown_file() {
	ocne catalog remove -N apptestcatalog
	ocne application uninstall --release onever-release --namespace onever-ns
	ocne application uninstall --release threevers-release --namespace threevers-ns
	ocne application uninstall --namespace check-custom --release check-custom-release
	ocne application uninstall --namespace check-zeroonezero --release check-zeroonezero-release
	ocne application uninstall --namespace check-defaults --release check-defaults-release
}

appFromKube() {
	KUBE="$1"
	run cut -d. -f1 <(echo "$KUBE")
	KUBE_MAJOR="$output"

	run cut -d. -f2 <(echo "$KUBE")
	KUBE_MINOR="$output"

	echo "$KUBE_MAJOR.$KUBE_MINOR.0"
}

@test "Installing onever application installs the correct version" {
	ocne application install --catalog apptestcatalog --name onever --namespace onever-ns --release onever-release
	run ocne application ls --namespace onever-ns
	run tail -n +3 <(echo "$output")
	run sh -c "echo $output | tr -s ' '"
	APP="$output"

	echo "$APP"
	echo "onever-release onever-ns onever deployed 1 $(appFromKube $KUBE_VERSION)"
	[ "$APP" = "onever-release onever-ns onever deployed 1 $(appFromKube $KUBE_VERSION)" ]
}

@test "Installing threevers application installs the correct version" {
	ocne application install --catalog apptestcatalog --name threevers --namespace threevers-ns --release threevers-release
	run ocne application ls --namespace threevers-ns
	run tail -n +3 <(echo "$output")
	run sh -c "echo $output | tr -s ' '"
	APP="$output"


	run cut -d. -f1 <(echo "$KUBE_VERSION")
	KUBE_MAJOR="$output"

	run cut -d. -f2 <(echo "$KUBE_VERSION")
	KUBE_MINOR="$output"

	echo "$APP"
	echo "threevers-release threevers-ns threevers deployed 1 $KUBE_MAJOR.$((KUBE_MINOR + 2)).0"
	[ "$APP" = "threevers-release threevers-ns threevers deployed 1 $KUBE_MAJOR.$((KUBE_MINOR + 2)).0" ]
}

@test "Installing check application with default values has correct resources" {
	ocne application install --catalog apptestcatalog --name check --namespace check-defaults --release check-defaults-release

	run -0 kubectl -n check-defaults get configmap check-defaults-release-check-0.2.0 -o yaml
	CM="$output"

	yq -e '.data.defaultKey == "defaultValue"'
	yq -e '.data.testKey == "0.2.0"'
}

@test "Installing check application at a specific version has correct resources" {
	ocne application install --catalog apptestcatalog --name check --namespace check-zeroonezero --release check-zeroonezero-release --version 0.1.0
	run -0 kubectl -n check-zeroonezero get configmap check-zeroonezero-release-check-0.1.0 -o yaml
	CM="$output"

	yq -e '.data.defaultKey == "defaultValue"'
	yq -e '.data.testKey == "0.1.0"'
}

@test "Installing check application with custom fields has correct values" {
	ocne application install --catalog apptestcatalog --name check --namespace check-custom --release check-custom-release --version 0.2.0 --values <( cat <<EOF
configMapContents:
  customKey: customVal
EOF
)
	run -0 kubectl -n check-custom get configmap check-custom-release-check-0.2.0 -o yaml
	CM="$output"

	yq -e '.data.defaultKey == "defaultValue"'
	yq -e '.data.testKey == "0.2.0"'
	yq -e '.data.customKey == "customVal"'
}

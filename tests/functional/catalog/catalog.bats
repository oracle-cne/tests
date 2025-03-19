#! /usr/bin/env bats
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=CATALOG
bats_require_minimum_version 1.5.0

setup_file() {
	ocne catalog add -u $(test-catalog-uri.sh) -N testcatalog
}

teardown_file() {
	ocne catalog remove -N testcatalog
	ocne catalog remove -N "ArtifactHub Community Catalog"
	ocne catalog remove -N "ACC-search"
}

checkKubeVer() {
	FIRST="$1"
	SECOND="$2"

	run cut -d. -f1 <(echo "$FIRST")
	FIRST_MAJOR="$output"

	run cut -d. -f2 <(echo "$FIRST")
	FIRST_MINOR="$output"

	run cut -d. -f1 <(echo "$SECOND")
	SECOND_MAJOR="$output"

	run cut -d. -f2 <(echo "$SECOND")
	SECOND_MINOR="$output"

	echo " $FIRST -> $FIRST_MAJOR.$FIRST_MINOR | $SECOND -> $SECOND_MAJOR.$SECOND_MINOR"
	[ "$FIRST_MAJOR" -eq "$SECOND_MAJOR" ]
	[ "$FIRST_MINOR" -eq "$SECOND_MINOR" ]

}

@test "Listing catalogs gives output" {
	run ocne catalog list
	[ $status -eq 0 ]
	[ $(echo "$output" | wc -l) -gt 1 ]

	run ocne catalog ls
	[ $status -eq 0 ]
	[ $(echo "$output" | wc -l) -gt 1 ]
}

@test "Catalogs can be added" {
	ocne catalog add -u https://artifacthub.io -N "ArtifactHub Community Catalog" -p artifacthub
}

@test "ArtifactHub catalogs can be searched" {
	ocne catalog add -u https://artifacthub.io -N "ACC-search" -p artifacthub
	ocne catalog search --name "ACC-search" --pattern ingress-nginx
}

@test "Embedded catalog can be searched" {
	run ocne catalog search --name embedded
	[ $status -eq 0 ]
	echo $output | grep -e 'flannel' -e 'cert-manager'
}

@test "Catalogs can be removed" {
	ocne catalog add -u https://artifacthub.io -N "ACC-remove" -p artifacthub
	ocne catalog remove -N "ACC-remove"
	run ocne catalog list
	[ "$status" -eq 0 ]
	[[ ! "$output" =~ "ACC-remove" ]]
}

@test "Getting a catalog produces output" {
	run ocne catalog get
	[ "$status" -eq 0 ]
	[ -n "$output" ]
}

@test "Catalog should only return one supported version for onever application in test catalog" {
	run -0 ocne catalog search -N testcatalog
	APPS="$output"

	run sh -c "echo \"$APPS\" | grep onever | tr -s ' ' | cut -f2"
	ONEVERS="$output"
	echo "$ONEVERS"

	run wc -l <(echo "$ONEVERS")
	run cut -d' ' -f1 <(echo "$output")
	[ "$output" -eq 1 ]

	checkKubeVer "$ONEVERS" "$KUBE_VERSION"

}

@test "Catalog should only return three supported versions for threever application in test catalog" {
	run -0 ocne catalog search -N testcatalog
	APPS="$output"

	run sh -c "echo \"$APPS\" | grep threever | tr -s ' ' | cut -f2"
	THREEVERS="$output"

	echo "$THREEVERS"
	run wc -l <(echo "$THREEVERS")
	run cut -d' ' -f1 <(echo "$output")
	[ "$output" -eq 3 ]

	# Entries should be sorted N, N-1, N-2
	run head -1 <(echo "$THREEVERS")
	MAX_VER="$output"

	run tail -1 <(echo "$THREEVERS")
	MIN_VER="$output"

	run tail -2 <(echo "$THREEVERS")
	run head -1 <(echo "$output")
	MIDDLE_VER="$output"

	run cut -d. -f1 <(echo "$KUBE_VERSION")
	KUBE_MAJOR="$output"

	run cut -d. -f2 <(echo "$KUBE_VERSION")
	KUBE_MINOR="$output"

	checkKubeVer "$MAX_VER" "$KUBE_MAJOR.$((KUBE_MINOR + 2))"
	checkKubeVer "$MIDDLE_VER" "$KUBE_MAJOR.$((KUBE_MINOR + 1))"
	checkKubeVer "$MIN_VER" "$KUBE_MAJOR.$KUBE_MINOR"
}

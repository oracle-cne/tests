#! /usr/bin/env bats
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=APPLICATION

@test "Generating a template for an application emits reasonable information" {
	run ocne application template --name grafana
	[ $status -eq 0 ]
	echo "$output" | grep 'repository:'
}

@test "Generating a template for an application emits reasonable information from embedded catalog" {
	run ocne application template --name grafana --catalog embedded
	[ $status -eq 0 ]
	echo "$output" | grep 'repository:'
}

@test "Setting EDITOR to a bad value causes an error" {
	export EDITOR="thishsouldfail"

	run -1 --separate-stderr ocne application template --interactive --name grafana
	echo "$stderr" | grep 'Allowed editors: vim, vi, nano, emacs'

}

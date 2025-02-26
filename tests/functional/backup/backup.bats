#! /usr/bin/env bats
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# bats file_tags=BACKUP

@test "The etcd backup can be created" {
	backupFile="$BATS_TEST_TMPDIR/backup.db"
	ocne cluster backup --out $backupFile
	[ -f "$backupFile" ]
}


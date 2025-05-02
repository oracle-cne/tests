#! /bin/bash
#
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

PARENT="$1"
CHILD="$2"
DESC="$3"

set -e
set -x

[ -n "$PARENT" ]
[ -n "$CHILD" ]
[ -n "$DESC" ]

PARENT_ID=
for comp in $(echo "$PARENT" | tr '/' ' '); do
	if [ -z "$PARENT_ID" ]; then
		COMPARTMENTS=$(oci iam compartment list)
	else
		COMPARTMENTS=$(oci iam compartment list --compartment-id "$PARENT_ID")
	fi
	PARENT_ID=$(printf "$COMPARTMENTS" | jq -r ".data[] | select (.name == \"$comp\") | .id")
	echo Compartment $comp has ocid $PARENT_ID
done

if [ -z "$PARENT_ID" ]; then
	echo Could not find $PARENT
	exit 1
fi

EXISTS=$(oci iam compartment list --compartment-id "$PARENT_ID" --name "$CHILD")
if [ -n "$EXISTS" ]; then
	printf "$EXISTS" | jq -r '.data[0].id'
	exit 0
fi


INFO=$(oci iam compartment create --compartment-id "$PARENT_ID" --name "$CHILD" --description "$DESC")
echo $(printf "$INFO" | jq '.id')

#!/usr/bin/env bash

# Input variables are:
# group - the group that should own the files in the path
# is_mount_point - a Boolean indicating whether or not the path is a
# mount point
# owner - the user that should own the files in the path
# path - the path to be recursively chowned

set -o nounset
set -o errexit
set -o pipefail

# If necessary, ensure the disk has been mounted
#
# This is a Terraform template file, and the is_mount_point and
# path variables are passed in via templatefile().
#
# shellcheck disable=SC2154
if "${is_mount_point}"; then
  until findmnt "${path}"; do
    sleep 5
    echo Waiting for "${path}" to be mounted...
  done
fi

# ensure the path exists
#
# This is a Terraform template file, and the path variable is passed
# in via templatefile().
#
# shellcheck disable=SC2154
mkdir --parents "${path}"

# chown the path
#
# This is a Terraform template file, and the group, owner, and path
# variables are passed in via templatefile().
#
# shellcheck disable=SC2154
chown --recursive "${owner}:${group}" "${path}"

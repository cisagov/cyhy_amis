#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Create the mongo journal mount point
mkdir --verbose --parents /var/lib/mongodb/journal

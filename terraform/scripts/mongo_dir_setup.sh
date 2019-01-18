#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Create the mongodb keyFile (if it's not already there)
stat /var/lib/mongodb/keyFile || openssl rand -base64 741 > /var/lib/mongodb/keyFile
chmod 600 /var/lib/mongodb/keyFile

# Make the mongodb user the owner of the mongodb directories
chown --verbose --recursive mongodb:mongodb /var/log/mongodb
chown --verbose --recursive mongodb:mongodb /var/lib/mongodb

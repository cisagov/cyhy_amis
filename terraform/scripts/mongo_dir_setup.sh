#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Create the mongodb keyFile (if it's not already there).
#
# openssl rand seems to require the RANDFILE bit, otherwise it fails
# with the error message "unable to write 'random state'".
export RANDFILE=/dev/null
stat /var/lib/mongodb/keyFile || \
    openssl rand -out /var/lib/mongodb/keyFile -base64 741

# Set the permissions on the keyFile
chmod 600 /var/lib/mongodb/keyFile

# Make the mongodb user the owner of the /var/lib/mongodb and
# /var/log/mongodb directories
chown --verbose --recursive mongodb:mongodb \
      /var/lib/mongodb /var/log/mongodb

#!/usr/bin/env bash

# This code works on all the Debian instances

set -o nounset
set -o errexit
set -o pipefail

ip_addr=$(hostname --all-ip-addresses | cut --delimiter=' ' --fields=1)

# The return value of variable=$(command) is the return value of the
# command.  We need this because sometimes at boot the host will
# resolve, then briefly fail to resolve while AWS networking settles
# into place.
while ! hostinfo=$(host "$ip_addr")
do
    echo Waiting for IP to resolve to an address...
    sleep 5
done

name=$(echo "$hostinfo" | \
           cut --delimiter=' ' --fields=5 | \
           sed 's/\([^\.]*\)\.\([^\.]*\)\./\1/')

hostnamectl set-hostname --no-ask-password "$name"

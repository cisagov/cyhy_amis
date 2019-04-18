#!/usr/bin/env bash

# This code works on all the Debian instances

set -o nounset
set -o errexit
set -o pipefail

ip_addr=$(hostname --all-ip-addresses | cut --delimiter=' ' --fields=1)

while ! host "$ip_addr"
do
    echo Waiting for IP to resolve to an address...
    sleep 5
done

name=$(host "$ip_addr" | \
           cut --delimiter=' ' --fields=5 | \
           sed 's/\(.*\)\.local\./\1/')

hostnamectl set-hostname "$name"

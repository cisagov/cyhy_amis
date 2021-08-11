#!/usr/bin/env bash

# create_ssm_variable.sh [args]
#
# Note that the args are precisely the arguments that would be passed
# to the command aws ssm put-parameter.

set -o nounset
set -o errexit
set -o pipefail

for region in us-east-1 us-east-2 us-west-1 us-west-2; do
  aws --region=$region ssm put-parameter "$@"
done

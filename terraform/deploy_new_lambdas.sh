#!/usr/bin/env bash

# deploy_new_lambdas.sh
# deploy_new_lambdas.sh workspace_name

set -o nounset
set -o errexit
set -o pipefail

workspace=prod-a
if [ $# -ge 1 ]
then
    workspace=$1
fi

terraform workspace select "$workspace"

for i in $(seq 0 2)
do
    terraform taint "aws_lambda_function.lambdas.$i"
done

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_lambda_function.lambdas \
          -target=aws_iam_role_policy.lambda_cloudwatch_policies \
          -target=aws_iam_role_policy.lambda_bod_docker_policy \
          -target=aws_cloudwatch_log_group.lambda_logs

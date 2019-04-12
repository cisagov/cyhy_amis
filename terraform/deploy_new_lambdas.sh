#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

for i in $(seq 0 2)
do
    terraform taint "aws_lambda_function.lambdas.$i"
done

terraform apply -var-file=prod-a.tfvars \
          -target=aws_lambda_function.lambdas \
          -target=aws_iam_role_policy.lambda_cloudwatch_policies \
          -target=aws_iam_role_policy.lambda_bod_docker_policy \
          -target=aws_cloudwatch_log_group.lambda_logs

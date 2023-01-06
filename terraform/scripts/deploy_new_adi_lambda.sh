#!/usr/bin/env bash

# deploy_new_adi_lambda.sh workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 1 ]; then
  workspace=$1
else
  echo "Usage:  deploy_new_adi_lambda.sh workspace_name"
  exit 1
fi

terraform workspace select "$workspace"

# taint the existing Lambda instance
terraform taint "aws_lambda_function.adi_lambda"

# recreate the new Lambda instance
terraform apply -var-file="$workspace.tfvars" \
  -target=aws_lambda_function.adi_lambda \
  -target=aws_lambda_permission.adi_lambda_allow_bucket \
  -target=aws_s3_bucket_notification.adi_lambda \
  -target=aws_cloudwatch_log_group.adi_lambda_logs \
  -target=aws_iam_role_policy.adi_lambda_cloudwatch_policy

#!/usr/bin/env bash

# deploy_new_adi_lambda.sh region workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 2 ]
then
    region=$1
    workspace=$2
else
    echo "Usage:  deploy_new_adi_lambda.sh region workspace_name"
    exit 1
fi

terraform workspace select "$workspace"

# taint the existing lambda instance
terraform taint "aws_lambda_function.adi_lambda"

# recreate the new lambda instance
terraform apply -var-file="$workspace.tfvars" \
          -target=aws_lambda_function.adi_lambda \
          -target=aws_lambda_permission.adi_lambda_allow_bucket \
          -target=aws_s3_bucket_notification.bucket_notification \
          -target=aws_cloudwatch_log_group.adi_lambda_logs

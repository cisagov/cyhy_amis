#!/usr/bin/env bash

# deploy_new_fdi_lambda.sh workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 1 ]
then
    workspace=$1
else
    echo "Usage:  deploy_new_fdi_lambda.sh workspace_name"
    exit 1
fi

terraform workspace select "$workspace"

# taint the existing lambda instance
terraform taint "aws_lambda_function.fdi_lambda"

# recreate the new lambda instance
terraform apply -var-file="$workspace.tfvars" \
          -target=aws_lambda_function.fdi_lambda \
          -target=aws_lambda_permission.fdi_lambda_allow_bucket \
          -target=aws_s3_bucket_notification.bucket_notification \
          -target=aws_cloudwatch_log_group.fdi_lambda_logs

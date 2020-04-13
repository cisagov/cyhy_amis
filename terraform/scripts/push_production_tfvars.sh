#!/bin/sh

# Push your current local version of production.tfvars to the correct
# S3 bucket so that it can be used by others
# Requirement: AWS command line interface must be installed/setup on your system

TERRAFORM_TFVARS_S3_BUCKET="ncats-terraform-production-tfvars"
TERRAFORM_DIR="terraform"
TFVARS_FILE="prod-a.tfvars"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

aws s3 cp ${SCRIPT_DIR}/../${TFVARS_FILE} s3://${TERRAFORM_TFVARS_S3_BUCKET}/${TERRAFORM_DIR}/${TFVARS_FILE}

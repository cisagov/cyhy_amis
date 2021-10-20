#!/bin/bash

# Fetch the current version of production.tfvars from an S3 bucket and put it
# in the terraform directory
# Requirement: AWS command line interface must be installed/setup on your system

TERRAFORM_TFVARS_S3_BUCKET="ncats-terraform-production-tfvars"
TERRAFORM_DIR="terraform_nessus_only"
TFVARS_FILE="production.tfvars"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aws s3 cp s3://${TERRAFORM_TFVARS_S3_BUCKET}/${TERRAFORM_DIR}/${TFVARS_FILE} "${SCRIPT_DIR}"/../${TFVARS_FILE}

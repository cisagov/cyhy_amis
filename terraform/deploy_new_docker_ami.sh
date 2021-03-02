#!/usr/bin/env bash

# deploy_new_docker_ami.sh region workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 2 ]
then
  region=$1
  workspace=$2
else
  echo "Usage:  deploy_new_docker_ami.sh region workspace_name"
  exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
docker_instance_id=$(terraform state show aws_instance.bod_docker | \
    sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
    grep "[[:space:]]id[[:space:]]" | \
  sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing docker instance
aws --region "$region" ec2 terminate-instances --instance-ids "$docker_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$docker_instance_id"

terraform apply -var-file="$workspace.tfvars" \
  -target=aws_instance.bod_docker \
  -target=aws_route53_record.bod_docker_A \
  -target=aws_route53_record.bod_rev_docker_PTR \
  -target=aws_volume_attachment.bod_report_data_attachment \
  -target=module.bod_docker_ansible_provisioner

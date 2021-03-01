#!/usr/bin/env bash

# deploy_new_bod_bastion_ami.sh region workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 2 ]
then
  region=$1
  workspace=$2
else
  echo "Usage:  deploy_new_bod_bastion_ami.sh region workspace_name"
  exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
bod_bastion_instance_id=$(terraform state show aws_instance.bod_bastion | \
    sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
    grep "[[:space:]]id[[:space:]]" | \
  sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing BOD bastion instance
aws --region "$region" ec2 terminate-instances --instance-ids "$bod_bastion_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$bod_bastion_instance_id"

terraform apply -var-file="$workspace.tfvars" \
  -target=aws_instance.bod_bastion \
  -target=aws_route53_record.bod_bastion_A \
  -target=aws_route53_record.bod_bastion_pub_A \
  -target=aws_route53_record.bod_rev_bastion_PTR \
  -target=aws_network_acl_rule.bod_public_ingress_from_docker \
  -target=aws_network_acl_rule.bod_public_ingress_from_lambda \
  -target=aws_network_acl_rule.bod_public_ingress_from_anywhere_via_ephemeral_ports \
  -target=aws_network_acl_rule.bod_public_ingress_from_anywhere_via_ssh \
  -target=aws_network_acl_rule.bod_public_egress_to_docker_via_ssh \
  -target=aws_network_acl_rule.bod_public_egress_to_bastion_via_ssh \
  -target=aws_network_acl_rule.bod_public_egress_anywhere \
  -target=aws_network_acl_rule.bod_public_egress_to_anywhere_via_ephemeral_ports \
  -target=aws_security_group_rule.bastion_ssh_from_trusted \
  -target=aws_security_group_rule.bastion_self_ssh \
  -target=aws_security_group_rule.bastion_ssh_to_docker

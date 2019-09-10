#!/usr/bin/env bash

# deploy_new_bastion_ami.sh region workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 2 ]
then
    region=$1
    workspace=$2
else
    echo "Usage:  deploy_new_bastion_ami.sh region workspace_name"
    exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
bastion_instance_id=$(terraform state show aws_instance.cyhy_bastion | \
                           sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
                           grep "[[:space:]]id[[:space:]]" | \
                           sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing bastion instance
aws --region "$region" ec2 terminate-instances --instance-ids "$bastion_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$bastion_instance_id"

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_instance.cyhy_bastion \
          -target=aws_route53_record.cyhy_bastion_A \
          -target=aws_route53_record.cyhy_bastion_pub_A \
          -target=aws_route53_record.cyhy_rev_bastion_PTR \
          -target=aws_network_acl_rule.private_egress_to_bastion_via_ephemeral_ports \
          -target=aws_network_acl_rule.private_ingress_from_bastion_via_ssh \
          -target=aws_security_group_rule.bastion_self_ingress \
          -target=aws_security_group_rule.bastion_self_egress \
          -target=aws_security_group_rule.bastion_egress_to_private_sg_via_ssh \
          -target=aws_security_group_rule.bastion_egress_to_scanner_sg_via_trusted_ports \
          -target=aws_security_group_rule.bastion_egress_to_mongo_via_mongo \
          -target=aws_security_group_rule.bastion_ingress_from_trusted_via_ssh \
          -target=aws_security_group_rule.bastion_egress_to_dashboard \
          -target=aws_security_group_rule.bastion_egress_for_webd \
          -target=aws_security_group_rule.private_ssh_ingress_from_bastion \
          -target=module.cyhy_bastion_ansible_provisioner

#!/usr/bin/env bash

# deploy_new_database_ami.sh region workspace_name

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 2 ]
then
    region=$1
    workspace=$2
else
    echo "Usage:  deploy_new_dashboard_ami.sh region workspace_name"
    exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
dashboard_instance_id=$(terraform state show aws_instance.cyhy_dashboard | \
                            sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
                            grep "[[:space:]]id[[:space:]]" | \
                            sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing mongo instance
aws --region "$region" ec2 terminate-instances --instance-ids "$dashboard_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$dashboard_instance_id"

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_instance.cyhy_dashboard \
          -target=aws_route53_record.cyhy_dashboard_A \
          -target=aws_route53_record.cyhy_rev_dashboard_PTR \
          -target=aws_security_group_rule.bastion_egress_to_dashboard \
          -target=aws_security_group_rule.bastion_egress_for_webd \
          -target=aws_security_group_rule.private_dashboard_ingress_from_bastion \
          -target=aws_security_group_rule.private_mongodb_ingress \
          -target=aws_security_group_rule.private_webd_egress_to_webui \
          -target=aws_security_group_rule.private_webd_ingress_from_bastion \
          -target=module.cyhy_dashboard_ansible_provisioner

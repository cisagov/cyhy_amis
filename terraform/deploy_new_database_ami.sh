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
    echo "Usage:  deploy_new_database_ami.sh region workspace_name"
    exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
database_instance_id=$(terraform state show aws_instance.cyhy_mongo[0] | \
                       sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
                       grep "[[:space:]]id[[:space:]]" | \
                       sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing mongo instance
aws --region "$region" ec2 terminate-instances --instance-ids "$database_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$database_instance_id"

terraform apply -var-file="$workspace.tfvars" \
                -target=aws_instance.cyhy_mongo \
                -target=aws_iam_role.cyhy_mongo_role \
                -target=aws_iam_role_policy.archive_cyhy_mongo_policy \
                -target=aws_iam_role_policy.es_cyhy_mongo_policy \
                -target=aws_iam_role_policy.s3_cyhy_mongo_policy \
                -target=aws_iam_instance_profile.cyhy_mongo \
                -target=aws_network_acl_rule.private_egress_to_mongo_via_mongo \
                -target=aws_route53_record.cyhy_database_A \
                -target=aws_route53_record.cyhy_rev_database_PTR \
                -target=aws_security_group_rule.adi_lambda_to_cyhy_mongo \
                -target=aws_security_group_rule.fdi_lambda_to_cyhy_mongo \
                -target=aws_security_group_rule.bastion_egress_to_mongo_via_mongo \
                -target=aws_security_group_rule.private_mongodb_egress_to_mongo_host \
                -target=aws_volume_attachment.cyhy_mongo_data_attachment \
                -target=aws_volume_attachment.cyhy_mongo_journal_attachment \
                -target=aws_volume_attachment.cyhy_mongo_log_attachment \
                -target=module.cyhy_mongo_ansible_provisioner

#!/usr/bin/env bash

# deploy_new_portscan_instance.sh region workspace_name instance_index

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 3 ]
then
    region=$1
    workspace=$2
    index=$3
else
    echo "Usage:  deploy_new_portscan_instance.sh region workspace_name instance_index"
    exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
#
# The first sed line has been carefully crafted to work with BSD sed.
nmap_instance_id=$(terraform state show aws_instance.cyhy_nmap[$index] | \
                       sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
                       grep "[[:space:]]id[[:space:]]" | \
                       sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing nmap instance
aws --region "$region" ec2 terminate-instances --instance-ids "$nmap_instance_id"
aws --region "$region" ec2 wait instance-terminated --instance-ids "$nmap_instance_id"

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_eip_association.cyhy_nmap_eip_assocs[$index] \
          -target=aws_instance.cyhy_nmap[$index] \
          -target=aws_route53_record.cyhy_portscan_A[$index] \
          -target=aws_route53_record.cyhy_rev_portscan_PTR[$index] \
          -target=aws_volume_attachment.nmap_cyhy_runner_data_attachment[$index] \
          -target="module.dyn_nmap.module.cyhy_nmap_ansible_provisioner_$index"

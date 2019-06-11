#!/usr/bin/env bash

# deploy_new_portscan_instance.sh instance_index
# deploy_new_portscan_instance.sh workspace_name instance_index

set -o nounset
set -o errexit
set -o pipefail

index=none
workspace=prod-a
if [ $# -eq 2 ]
then
    workspace=$1
    index=$2
elif [ $# -eq 1 ]
then
    index=$1
else
    echo "Usage:  deploy_new_portscan_instance.sh instance_index"
    echo "        deploy_new_portscan_instance.sh workspace_name instance_index"
    exit 1
fi

terraform workspace select "$workspace"

# Strip control characters, then look for the text "id" surrounded by
# space characters, then extract only the ID from that line.
nmap_instance_id=$(terraform state show aws_instance.cyhy_nmap[$index] | \
                       sed $'s,\x1b\\[[0-9;]*[[:alpha:]]],,g' | \
                       grep "[[:space:]]id[[:space:]]" | \
                       sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

# Terminate the existing nmap instance
aws ec2 terminate-instances --instance-ids "$nmap_instance_id"
aws ec2 wait instance-terminated --instance-ids "$nmap_instance_id"

terraform apply -var-file="$workspace.tfvars" \
          -target=aws_eip_association.cyhy_nmap_eip_assocs[$index] \
          -target=aws_instance.cyhy_nmap[$index] \
          -target=aws_route53_record.cyhy_portscan_A[$index] \
          -target=aws_route53_record.cyhy_rev_portscan_PTR[$index] \
          -target=aws_volume_attachment.nmap_cyhy_runner_data_attachment[$index] \
          -target="module.dyn_nmap.module.cyhy_nmap_ansible_provisioner_$index"

#!/usr/bin/env bash

# deploy_new_portscan_instance.sh region workspace_name instance_index
# deploy_new_portscan_instance.sh region workspace_name first_instance last_instance

set -o nounset
set -o errexit
set -o pipefail

function usage {
    echo "Usage:"
    echo "  ${0##*/} region workspace_name instance_index"
    echo "  ${0##*/} region workspace_name first_instance last_instance"
    exit 1
}

function redeploy_instances {
    tf_args="-var-file=\"$workspace.tfvars\""
    for index in $(seq "$1" "$2")
    do
        # Strip control characters, then look for the text "id" surrounded by
        # space characters, then extract only the ID from that line.
        # The first sed line has been carefully crafted to work with BSD sed.
        nmap_instance_id=$(terraform state show aws_instance.cyhy_nmap[$index] | \
                               sed $'s,\x1b\\[[0-9;]*[[:alpha:]],,g' | \
                               grep "[[:space:]]id[[:space:]]" | \
                               sed "s/[[:space:]]*id[[:space:]]*= \"\(.*\)\"/\1/")

        # Terminate the existing nmap instance
        aws --region "$region" ec2 terminate-instances --instance-ids "$nmap_instance_id"
        aws --region "$region" ec2 wait instance-terminated --instance-ids "$nmap_instance_id"

        tf_args="$tf_args -target=aws_eip_association.cyhy_nmap_eip_assocs[$index]"
        tf_args="$tf_args -target=aws_instance.cyhy_nmap[$index]"
        tf_args="$tf_args -target=aws_route53_record.cyhy_portscan_A[$index]"
        tf_args="$tf_args -target=aws_route53_record.cyhy_rev_portscan_PTR[$index]"
        tf_args="$tf_args -target=aws_volume_attachment.nmap_cyhy_runner_data_attachment[$index]"
        tf_args="$tf_args -target=\"module.dyn_nmap.module.cyhy_nmap_ansible_provisioner_$index\""
    done

    terraform apply $tf_args
}

if [ $# -eq 3 ]
then
    stop=$3
elif [ $# -eq 4 ]
then
    stop=$4
else
    usage
fi

region=$1
workspace=$2
start=$3

if [ "$start" -gt "$stop" ]
then
    usage
fi

terraform workspace select "$workspace"
redeploy_instances "$start" "$stop"

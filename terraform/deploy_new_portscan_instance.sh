#!/usr/bin/env bash
#
# (Re)deploy portscan instances in the current Terraform environment.
# Usage:
# deploy_new_portscan_instance.sh region workspace_name instance_index
# deploy_new_portscan_instance.sh region workspace_name first_index last_index

set -o nounset
set -o errexit
set -o pipefail

# Print usage information and exit.
function usage {
  echo "Usage:"
  echo "  ${0##*/} region workspace_name instance_index"
  echo "  ${0##*/} region workspace_name first_index last_index"
  echo
  echo "Notes:"
  echo "  - When giving a first and last index the range is inclusive."
  exit 1
}

# Check for required external programs. If any are missing output a list of all
# requirements and then exit.
function check_dependencies {
  if [ -z "$(command -v terraform)" ] || \
    [ -z "$(command -v aws)" ] || \
    [ -z "$(command -v jq)" ]
  then
    echo "This script requires the following tools to run:"
    echo "- terraform"
    echo "- aws (AWS CLI)"
    echo "- jq"
    exit 1
  fi
}

# Terminate running instances and (re)deploy their Terraform resources in the
# given range of instance indices [first, last].
function redeploy_instances {
  tf_args=()
  # Get all portscan instance IDs as a JSON array of dicts in the form:
  # {
  #   index: instance_index,
  #   id: instance_id
  # }
  # Any previously removed instances are ignored (.deposed_key == null)
  portscanner_ids_json=$(terraform show -json | \
      jq '.values.root_module.resources[] | select(.address == "aws_instance.cyhy_nmap" and .deposed_key == null) | {index, id: .values.id}' \
    | jq -n '[inputs]')
  nmap_instance_ids=()

  for index in $(seq "$1" "$2")
  do
    # Check the list of instances and get the ID of the index we are working
    # on for this iteration and add it to the array of IDs if found
    instance_id="$(echo "$portscanner_ids_json" | jq --raw-output ".[] | select(.index == $index) | .id")"
    if [ -n "$instance_id" ]
    then
      nmap_instance_ids+=("$instance_id")
    else
      echo "No instance ID found for portscan$(($index+1))"
    fi

    tf_args+=("-target=aws_eip_association.cyhy_nmap_eip_assocs[$index]")
    tf_args+=("-target=aws_instance.cyhy_nmap[$index]")
    tf_args+=("-target=aws_route53_record.cyhy_portscan_A[$index]")
    tf_args+=("-target=aws_route53_record.cyhy_rev_portscan_PTR[$index]")
    tf_args+=("-target=aws_volume_attachment.nmap_cyhy_runner_data_attachment[$index]")
    tf_args+=("-target=module.dyn_nmap.module.cyhy_nmap_ansible_provisioner_$index")
  done

  if [ ${#nmap_instance_ids[@]} -ne 0 ]
  then
    # Terminate the existing nmap instance
    aws --region "$region" ec2 terminate-instances --instance-ids "${nmap_instance_ids[@]}"
    aws --region "$region" ec2 wait instance-terminated --instance-ids "${nmap_instance_ids[@]}"
  fi
  terraform apply -var-file="$workspace.tfvars" "${tf_args[@]}"
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

if [[ (! "$start" =~ ^[0-9]+$) || (! "$stop" =~ ^[0-9]+$) ]]
then
  usage
fi

if [ "$start" -gt "$stop" ]
then
  usage
fi

check_dependencies

terraform workspace select "$workspace"
redeploy_instances "$start" "$stop"

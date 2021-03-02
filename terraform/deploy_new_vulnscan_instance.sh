#!/usr/bin/env bash
#
# (Re)deploy vulnscan instances in the current Terraform environment.
# Usage:
# deploy_new_vulnscan_instance.sh region workspace_name instance_index
# deploy_new_vulnscan_instance.sh region workspace_name first_index last_index

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
  # Get all vulnscan instance IDs as a JSON array of dicts in the form:
  # {
  #   index: instance_index,
  #   id: instance_id
  # }
  # Any previously removed instances are ignored (.deposed_key == null)
  vulnscanner_ids_json=$(terraform show -json | \
      jq '.values.root_module.resources[] | select(.address == "aws_instance.cyhy_nessus" and .deposed_key == null) | {index, id: .values.id}' \
    | jq -n '[inputs]')
  nessus_instance_ids=()

  for index in $(seq "$1" "$2")
  do
    # Check the list of instances and get the ID of the index we are working
    # on for this iteration
    nessus_instance_ids+=("$(echo "$vulnscanner_ids_json" | jq --raw-output ".[] | select(.index == $index) | .id")")

    tf_args+=("-target=aws_eip_association.cyhy_nessus_eip_assocs[$index]")
    tf_args+=("-target=aws_instance.cyhy_nessus[$index]")
    tf_args+=("-target=aws_route53_record.cyhy_vulnscan_A[$index]")
    tf_args+=("-target=aws_route53_record.cyhy_rev_vulnscan_PTR[$index]")
    tf_args+=("-target=aws_volume_attachment.nessus_cyhy_runner_data_attachment[$index]")
    tf_args+=("-target=module.dyn_nessus.module.cyhy_nessus_ansible_provisioner_$index")
  done

  if [ ${#nessus_instance_ids[@]} -ne 0 ]
  then
    # Terminate the existing nessus instance
    aws --region "$region" ec2 terminate-instances --instance-ids "${nessus_instance_ids[@]}"
    aws --region "$region" ec2 wait instance-terminated --instance-ids "${nessus_instance_ids[@]}"
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

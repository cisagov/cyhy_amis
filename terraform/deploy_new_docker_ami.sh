#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

docker_instance_id=$(terraform state show aws_instance.bod_docker | \
                         grep "^id" | sed "s/^id *= \(.*\)/\1/")

# Terminate the existing docker instance
aws ec2 terminate-instances --instance-ids "$docker_instance_id"
aws ec2 wait instance-terminated --instance-ids "$docker_instance_id"

terraform apply -var-file=prod-a.tfvars \
          -target=aws_instance.bod_docker \
          -target=aws_route53_record.bod_docker_A \
          -target=aws_route53_record.bod_rev_docker_PTR \
          -target=aws_volume_attachment.bod_report_data_attachment \
          -target=module.bod_docker_ansible_provisioner

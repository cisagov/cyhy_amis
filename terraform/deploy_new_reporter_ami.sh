#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

reporter_instance_id=$(terraform state show aws_instance.cyhy_reporter | \
                           grep "^id" | sed "s/^id *= \(.*\)/\1/")

# Terminate the existing reporter instance
aws ec2 terminate-instances --instance-ids "$reporter_instance_id"
aws ec2 wait instance-terminated --instance-ids "$reporter_instance_id"

terraform apply -var-file=prod-a.tfvars \
          -target=aws_instance.cyhy_reporter \
          -target=aws_route53_record.cyhy_reporter_A \
          -target=aws_route53_record.cyhy_rev_reporter_PTR \
          -target=aws_security_group_rule.private_mongodb_ingress \
          -target=aws_volume_attachment.cyhy_reporter_data_attachment \
          -target=module.cyhy_reporter_ansible_provisioner

# Cyber Hygiene and BOD 18-01 Scanning Terraform Code for AWS ☁️ #

## Pre-requisites ##

In order to access certain AWS resources, the following AWS profiles must be
set up in your AWS credentials file:

- `cool-dns-route53resourcechange-cyber.dhs.gov`
- `cool-terraform-readstate`

The easiest way to set up those profiles is to use our
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync) utility.
Follow the usage instructions in that repository before continuing with the
next steps.  Note that you will need to know where your team stores their
remote profile data in order to use
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync).

## Building ##

Build Terraform-based infrastructure with:

```console
ansible-galaxy install --role-file ansible/requirements.yml
cd terraform
terraform workspace select <your_workspace>
terraform init
terraform apply -var-file=<your_workspace>.tfvars
```

Also note that

```console
ansible-galaxy install --force --role-file ansible/requirements.yml
```

will update the roles that are being pulled from external sources.  This
may be required, for example, if a role that is being pulled from a
GitHub repository has been updated and you want the new changes.  By
default `ansible-galaxy install` *will not* upgrade roles.

## Destroying ##

Tear down Terraform-based infrastructure with:

```console
cd terraform
terraform workspace select <your_workspace>
terraform init
terraform destroy -var-file=<your_workspace>.tfvars
```

## `ssh` configuration for connecting to EC2 instances ##

You can use `ssh` to connect directly to the bastion EC2 instances in the
Cyber Hygiene and BOD VPCs:

```console
ssh bastion.<your_workspace>.cyhy
ssh bastion.<your_workspace>.bod
```

Other EC2 instances in these two VPCs can only be connected to by
proxying the `ssh` connection via the corresponding bastion host.
This can be done automatically by `ssh` if you add something like the
following to your `~/.ssh/config`:

```ssh-config
Host *.bod *.cyhy
     User <your_username>

Host bastion.*.bod bastion.*.cyhy
     HostName %h.cyber.dhs.gov

Host !bastion.*.bod *.bod !bastion.*.cyhy *.cyhy
     ProxyCommand ssh -W $(sed "s/^\([^.]*\)\..*$/\1/" <<< %h):22 $(sed s/^[^.]*/bastion/ <<< %h)
```

This `ssh` configuration snippet allows you to `ssh` directly to
`reporter.<your_workspace>.cyhy` or `docker.<your_workspace>.bod`,
for example:

```console
ssh reporter.<your_workspace>.cyhy
ssh docker.<your_workspace>.bod
```

## `ssh` port forwarding ##

You may also find it helpful to configure `ssh` to automatically
forward the Nessus UI and MongoDB ports when connecting to the Cyber
Hygiene VPC:

```ssh-config
Host bastion.*.cyhy
     LocalForward 8834 vulnscan1:8834
     LocalForward 8835 vulnscan2:8834
     LocalForward 0.0.0.0:27017 database1:27017
```

Note that the last `LocalForward` line forwards port 27017 *on any
interface* to port 27017 on the MongoDB instance.  This allows any
local Docker containers to take advantage of the port forwarding.

## Creating the management VPC ##

To create the management VPC, first modify your Terraform variables file
(`<your_workspace>.tfvars`) such that:

```hcl
enable_mgmt_vpc = true
```

If you want to include one or more Nessus instances in your management VPC,
ensure that the correct license keys are entered in your Terraform variables
file:

```hcl
mgmt_nessus_activation_codes = [ "LICENSE-KEY-1", "LICENSE-KEY-2" ]
```

At this point, you are ready to create all of the management VPC infrastructure
by running:

```console
terraform apply -var-file=<your_workspace>.tfvars
```

## Destroying the management VPC ##

To destroy the management VPC, first modify your Terraform variables file
(`<your_workspace>.tfvars`) such that:

```hcl
enable_mgmt_vpc = false
```

At this point, you are ready to destroy all of the management VPC
infrastructure by running:

```console
terraform apply -var-file=<your_workspace>.tfvars
```

## Requirements ##

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 3.75 |
| cloudinit | ~> 2.0 |

## Providers ##

| Name | Version |
|------|---------|
| aws | ~> 3.75 |
| aws.public\_dns | ~> 3.75 |
| cloudinit | ~> 2.0 |
| null | n/a |
| terraform | n/a |

## Modules ##

| Name | Source | Version |
|------|--------|---------|
| bod\_docker\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_bastion\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_dashboard\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_mongo\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_nessus\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_nmap\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| cyhy\_reporter\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| mgmt\_bastion\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |
| mgmt\_nessus\_ansible\_provisioner | github.com/cloudposse/terraform-null-ansible | n/a |

## Resources ##

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.adi_lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.bod_flow_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.cyhy_flow_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.fdi_lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.instance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.mgmt_flow_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.kevsync_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_log_metric_filter.nvdsync_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.kevsync_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.nvdsync_failure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_default_route_table.bod_default_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_default_route_table.cyhy_default_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_default_route_table.mgmt_default_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_ebs_volume.bod_report_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.cyhy_mongo_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.cyhy_mongo_journal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.cyhy_mongo_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.cyhy_reporter_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.nessus_cyhy_runner_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.nmap_cyhy_runner_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.vdp_report_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.bod_nonproduction_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.cyhy_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.cyhy_nessus_random_eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.cyhy_nmap_random_eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.mgmt_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.cyhy_nessus_eip_assocs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_eip_association.cyhy_nmap_eip_assocs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_flow_log.bod_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_flow_log.cyhy_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_flow_log.mgmt_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_access_key.moe_user_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_instance_profile.bod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_nmap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.cyhy_reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.dmarc_es_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_eni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.moe_bucket_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.moe_bucket_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_cyhy_archive_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ses_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.adi_lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bod_bastion_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bod_docker_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bod_flow_log_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_bastion_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_dashboard_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_flow_log_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_mongo_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_nessus_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_nmap_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cyhy_reporter_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.fdi_lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.mgmt_flow_log_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.adi_lambda_cloudwatch_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.adi_lambda_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.adi_lambda_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.bod_flow_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cyhy_flow_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.fdi_lambda_cloudwatch_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.fdi_lambda_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.fdi_lambda_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_bod_docker_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_cloudwatch_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mgmt_flow_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_bod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_nmap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent_policy_attachment_cyhy_reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.dmarc_es_assume_role_policy_attachment_bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.dmarc_es_assume_role_policy_attachment_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_eni_policy_attachment_adi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_eni_policy_attachment_bod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_eni_policy_attachment_fdi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.moe_bucket_write_policy_attachment_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_cyhy_archive_write_policy_attachment_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ses_assume_role_policy_attachment_bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ses_assume_role_policy_attachment_cyhy_reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_bod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_nmap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_agent_policy_attachment_cyhy_reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.moe_user_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.moe_bucket_read_policy_attachment_moe_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_instance.bod_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_nmap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.cyhy_reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.mgmt_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.mgmt_nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.bod_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_internet_gateway.cyhy_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_internet_gateway.mgmt_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lambda_function.adi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.fdi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambdas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.adi_lambda_allow_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.fdi_lambda_allow_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_nat_gateway.bod_nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.cyhy_nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.mgmt_nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.bod_docker_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.bod_lambda_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.bod_public_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.cyhy_portscanner_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.cyhy_private_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.cyhy_public_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.cyhy_vulnscanner_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.mgmt_private_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.mgmt_public_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.bod_private_egress_all_to_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_private_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_egress_all_to_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_egress_to_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_egress_to_bastion_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_egress_to_docker_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_ingress_from_anywhere_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_ingress_from_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.bod_public_ingress_from_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.cyhy_private_egress_all_to_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.cyhy_private_egress_anywhere_via_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.cyhy_private_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.cyhy_public_ingress_from_anywhere_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.docker_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.docker_egress_to_public_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.docker_ingress_anywhere_via_ephemeral_ports_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.docker_ingress_from_public_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.lambda_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.lambda_ingress_anywhere_via_ephemeral_ports_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_egress_anywhere_via_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_egress_to_bastion_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_egress_to_bod_vpc_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_egress_to_cyhy_vpc_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_egress_to_mgmt_public_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_ingress_from_bod_vpc_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_ingress_from_cyhy_vpc_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_ingress_from_mgmt_public_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_private_ingress_from_public_via_nessus_and_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_egress_all_to_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_egress_to_anywhere_via_tcp_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_egress_to_bastion_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_egress_to_private_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_ingress_from_anywhere_via_ephemeral_ports_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_ingress_from_anywhere_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_ingress_from_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.mgmt_public_ingress_from_private_via_port_53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_egress_to_anywhere_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_ingress_from_anywhere_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_ingress_from_private_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.portscanner_ingress_from_public_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_egress_to_bastion_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_egress_to_bod_docker_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_egress_to_mongo_via_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_egress_to_portscanner_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_egress_to_vulnscanner_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_ingress_from_bastion_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_egress_to_anywhere_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_all_from_mgmt_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_from_anywhere_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_from_portscanner_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_from_private_via_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress_from_vulncanner_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_egress_to_anywhere_via_any_port](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_ingress_all_from_mgmt_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_ingress_from_anywhere_via_ephemeral_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_ingress_from_anywhere_via_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_ingress_from_private_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.vulnscanner_ingress_from_public_via_nessus_and_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route.bod_public_route_external_traffic_through_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.bod_public_route_mgmt_traffic_through_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.bod_route_cyhy_traffic_through_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.bod_route_external_traffic_through_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.bod_route_mgmt_traffic_through_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.cyhy_default_route_external_traffic_through_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.cyhy_default_route_mgmt_traffic_through_mgmt_vpc_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.cyhy_private_route_external_traffic_through_bod_vpc_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.cyhy_private_route_external_traffic_through_mgmt_vpc_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.cyhy_private_route_external_traffic_through_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_public_route_external_traffic_through_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_route_bod_traffic_through_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_route_cyhy_traffic_through_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_route_external_traffic_through_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_record.bod_bastion_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_bastion_pub_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_docker_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_ns_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_reserved_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_rev_1_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_rev_2_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_rev_3_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_rev_bastion_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_rev_docker_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.bod_router_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_bastion_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_bastion_pub_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_dashboard_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_database_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_nessus_pub_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_ns_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_portscan_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_reporter_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_reserved_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_1_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_2_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_3_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_bastion_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_dashboard_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_database_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_portscan_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_reporter_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_rev_vulnscan_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_router_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cyhy_vulnscan_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_bastion_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_bastion_pub_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_ns_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_reserved_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_rev_1_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_rev_2_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_rev_3_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_rev_bastion_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_rev_nessus_PTR](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_router_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mgmt_vulnscan_A](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.bod_private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.bod_private_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.bod_public_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.cyhy_private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.cyhy_public_private_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.cyhy_scanner_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.mgmt_private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.mgmt_private_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.mgmt_public_zone_reverse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone_association.mgmt_bod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_route53_zone_association.mgmt_cyhy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_route_table.bod_public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.cyhy_private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.mgmt_public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.bod_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.cyhy_private_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.mgmt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.cyhy_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.moe_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.adi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_notification.fdi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.cyhy_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.moe_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.cyhy_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.moe_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cyhy_archive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.moe_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.adi_lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bod_bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bod_docker_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bod_lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cyhy_bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cyhy_private_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cyhy_scanner_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.fdi_lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.mgmt_bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.mgmt_scanner_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.adi_lambda_https_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.adi_lambda_to_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_egress_for_webd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_egress_to_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_egress_to_mongo_via_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_egress_to_private_sg_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_egress_to_scanner_sg_via_trusted_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_ingress_from_trusted_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_self_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_ssh_from_trusted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_ssh_to_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_egress_all_icmp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_egress_all_tcp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_egress_all_udp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_ingress_all_icmp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_bastion_ingress_all_udp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_egress_all_icmp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_egress_all_tcp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_egress_all_udp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_ingress_all_icmp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bod_docker_ingress_all_udp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_egress_all_icmp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_egress_all_tcp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_egress_all_udp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_ingress_all_icmp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cyhy_bastion_ingress_all_udp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_egress_to_cyhy_private_via_mongodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_ssh_ingress_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ephemeral_port_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.fdi_lambda_https_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.fdi_lambda_to_cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_egress_all_icmp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_egress_all_tcp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_egress_all_udp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_egress_to_scanner_sg_via_trusted_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_ingress_all_icmp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_ingress_all_udp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_ingress_from_trusted_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_bastion_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_egress_to_cyhy_and_bod_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_https_egress_to_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_ingress_from_bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_ingress_icmp_from_cyhy_and_bod_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_ingress_tcp_from_cyhy_and_bod_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.mgmt_scanner_ingress_udp_from_cyhy_and_bod_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_dashboard_ingress_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_egress_all_icmp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_egress_all_tcp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_egress_all_udp_to_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_https_egress_to_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_ingress_all_icmp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_ingress_all_udp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_egress_to_mongo_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_ingress_from_adi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_ingress_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_ingress_from_bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_mongodb_ingress_from_fdi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_ssh_egress_to_scanner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_ssh_ingress_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_webd_egress_to_webui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_webd_ingress_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_egress_anywhere](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_all_tcp_from_mgmt_vulnscan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_anywhere_icmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_anywhere_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_anywhere_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_from_bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.scanner_ingress_from_private_sg_via_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sns_topic.cloudwatch_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.fdi_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.kevsync_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.fdi_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.account_email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.fdi_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.kevsync_failure_email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_subnet.bod_docker_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.bod_lambda_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.bod_public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cyhy_portscanner_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cyhy_private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cyhy_public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.cyhy_vulnscanner_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.mgmt_private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.mgmt_public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_volume_attachment.bod_report_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.cyhy_mongo_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.cyhy_mongo_journal_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.cyhy_mongo_log_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.cyhy_reporter_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.nessus_cyhy_runner_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.nmap_cyhy_runner_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.vdp_report_data_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_vpc.bod_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc.cyhy_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc.mgmt_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.bod_dhcp_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options.cyhy_dhcp_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options.mgmt_dhcp_options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.bod_vpc_dhcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_dhcp_options_association.cyhy_vpc_dhcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_dhcp_options_association.mgmt_vpc_dhcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_peering_connection.bod_mgmt_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection.cyhy_bod_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection.cyhy_mgmt_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection_options.bod_mgmt_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options) | resource |
| [aws_vpc_peering_connection_options.cyhy_bod_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options) | resource |
| [aws_vpc_peering_connection_options.cyhy_mgmt_peering_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options) | resource |
| [null_resource.cyhy_nessus_pub_PTR](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.bod_docker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.cyhy_mongo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.nessus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.nmap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.reporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_eip.bod_production_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eip) | data source |
| [aws_eip.cyhy_nessus_eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eip) | data source |
| [aws_eip.cyhy_nmap_eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eip) | data source |
| [aws_iam_policy_document.adi_lambda_cloudwatch_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.adi_lambda_s3_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.adi_lambda_ssm_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bod_flow_log_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cyhy_flow_log_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dmarc_es_assume_role_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ec2_service_assume_role_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fdi_failure_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fdi_lambda_cloudwatch_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fdi_lambda_s3_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fdi_lambda_ssm_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_bod_docker_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_cloudwatch_docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_eni_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_service_assume_role_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.mgmt_flow_log_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.moe_bucket_read_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.moe_bucket_write_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_cyhy_archive_write_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ses_assume_role_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flow_log_service_assume_role_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.adi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_bucket.assessment_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_bucket.fdi_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_bucket.findings_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [cloudinit_config.bod_bastion_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.bod_docker_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_bastion_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_dashboard_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_mongo_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_nessus_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_nmap_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.cyhy_reporter_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.mgmt_bastion_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.mgmt_nessus_cloud_init_tasks](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [terraform_remote_state.dns](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs ##

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_prefixes | An object whose keys are the types of Packer images (defined in the `packer/` directory in the root of the repository) and whose values are the prefix to use for the corresponding AMI. The default for all images is "cyhy". | `object({ bastion = string, dashboard = string, docker = string, mongo = string, nessus = string, nmap = string, reporter = string })` | ```{ "bastion": "cyhy", "dashboard": "cyhy", "docker": "cyhy", "mongo": "cyhy", "nessus": "cyhy", "nmap": "cyhy", "reporter": "cyhy" }``` | no |
| assessment\_data\_filename | The name of the assessment data JSON file that can be found in the assessment\_data\_s3\_bucket. | `string` | n/a | yes |
| assessment\_data\_import\_db\_hostname | The hostname that has the database to store the assessment data in. | `string` | `""` | no |
| assessment\_data\_import\_db\_port | The port that the database server is listening on. | `string` | `""` | no |
| assessment\_data\_import\_lambda\_description | The description to associate with the assessment-data-import Lambda function. | `string` | `"Lambda function for importing assessment data."` | no |
| assessment\_data\_import\_lambda\_handler | The entrypoint for the assessment-data-import Lambda. | `string` | `"lambda_handler.handler"` | no |
| assessment\_data\_import\_lambda\_s3\_bucket | The name of the bucket where the assessment data import Lambda function can be found.  This bucket should be created with the cisagov/assessment-data-import-terraform project.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace\_name>' will be appended to the bucket name. | `string` | n/a | yes |
| assessment\_data\_import\_lambda\_s3\_key | The key (name) of the zip file for the assessment data import Lambda function inside the S3 bucket. | `string` | n/a | yes |
| assessment\_data\_import\_ssm\_db\_name | The name of the parameter in AWS SSM that holds the name of the database to store the assessment data in. | `string` | `""` | no |
| assessment\_data\_import\_ssm\_db\_password | The name of the parameter in AWS SSM that holds the database password for the user with write permission to the assessment database. | `string` | `""` | no |
| assessment\_data\_import\_ssm\_db\_user | The name of the parameter in AWS SSM that holds the database username with write permission to the assessment database. | `string` | `""` | no |
| assessment\_data\_s3\_bucket | The name of the bucket where the assessment data JSON file can be found.  Note that in production Terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace\_name>' will be appended to the bucket name. | `string` | `""` | no |
| aws\_availability\_zone | The AWS availability zone to deploy into (e.g. a, b, c, etc.). | `string` | `"a"` | no |
| aws\_region | The AWS region to deploy into (e.g. us-east-1). | `string` | `"us-east-1"` | no |
| bod\_lambda\_function\_bucket | The name of the S3 bucket where the Lambda function zip files reside.  Terraform cannot access buckets that are not in the provider's region, so the region name will be appended to the bucket name to obtain the actual bucket where the zips are stored.  So if we are working in region `us-west-1` and this variable has the value `buckethead`, then the zips will be looked for in the bucket `buckethead-us-west-1`. | `string` | n/a | yes |
| bod\_lambda\_functions | A map of information for each BOD 18-01 Lambda. The keys are the scan types and the values are objects that contain the Lambda's name and the key (name) for the corresponding deployment package in the BOD Lambda S3 bucket. Example: `{ pshtt = { lambda_file = "pshtt.zip", lambda_name = "task_pshtt" }}` | `map(object({ lambda_file = string, lambda_name = string }))` | `{}` | no |
| bod\_nat\_gateway\_eip | The IP corresponding to the EIP to be used for the BOD 18-01 NAT gateway in production.  In a non-production workspace an EIP will be created. | `string` | `""` | no |
| cloudwatch\_alarm\_emails | A list of the emails to which alerts should be sent if any CloudWatch Alarm is triggered. | `list(string)` | ```[ "cisa-cool-group+cyhy@trio.dhs.gov" ]``` | no |
| commander\_config | Configuration options for the CyHy commander's configuration file. | `object({ next_scan_limit = number })` | ```{ "next_scan_limit": 8192 }``` | no |
| create\_bod\_flow\_logs | Whether or not to create flow logs for the BOD 18-01 VPC. | `bool` | `false` | no |
| create\_cyhy\_flow\_logs | Whether or not to create flow logs for the CyHy VPC. | `bool` | `false` | no |
| create\_mgmt\_flow\_logs | Whether or not to create flow logs for the Management VPC. | `bool` | `false` | no |
| cyhy\_archive\_bucket\_name | S3 bucket for storing compressed archive files created by cyhy-archive. | `string` | `"ncats-cyhy-archive"` | no |
| cyhy\_elastic\_ip\_cidr\_block | The CIDR block of elastic addresses available for use by CyHy scanner instances. | `string` | `""` | no |
| cyhy\_portscan\_first\_elastic\_ip\_offset | The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy portscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first portscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional portscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available. | `number` | `0` | no |
| cyhy\_vulnscan\_first\_elastic\_ip\_offset | The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy vulnscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first vulnscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional vulnscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available. | `number` | `1` | no |
| dmarc\_import\_aws\_region | The AWS region where the dmarc-import Elasticsearch database resides. | `string` | `"us-east-1"` | no |
| dmarc\_import\_es\_role\_arn | The ARN of the role that must be assumed in order to read the dmarc-import Elasticsearch database. | `string` | n/a | yes |
| docker\_mailer\_override\_filename | This file is used to add/override any Docker composition settings for cyhy-mailer for the docker EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer. | `string` | `"docker-compose.bod.yml"` | no |
| enable\_mgmt\_vpc | Whether or not to enable unfettered access from the vulnerability scanner in the Management VPC to other VPCs (CyHy, BOD).  This should only be enabled while running security scans from the Management VPC. | `bool` | `false` | no |
| findings\_data\_field\_map | The key for the file storing field name mappings in JSON format. | `string` | n/a | yes |
| findings\_data\_import\_db\_hostname | The hostname that has the database to store the findings data in. | `string` | `""` | no |
| findings\_data\_import\_db\_port | The port that the database server is listening on. | `string` | `""` | no |
| findings\_data\_import\_lambda\_description | The description to associate with the findings-data-import Lambda function. | `string` | `"Lambda function for importing findings data."` | no |
| findings\_data\_import\_lambda\_failure\_emails | A list of the emails to which alerts should be sent if findings data processing fails. | `list(string)` | `[]` | no |
| findings\_data\_import\_lambda\_failure\_prefix | The object prefix that findings JSONs that have failed to process successfully will have in the findings data bucket. | `string` | `"failed/"` | no |
| findings\_data\_import\_lambda\_failure\_suffix | The object suffix that findings JSONs that have failed to process successfully will have in the findings data bucket. | `string` | `".json"` | no |
| findings\_data\_import\_lambda\_handler | The entrypoint for the findings-data-import Lambda. | `string` | `"lambda_handler.handler"` | no |
| findings\_data\_import\_lambda\_s3\_bucket | The name of the bucket where the findings data import Lambda function can be found.  This bucket should be created with the cisagov/findings-data-import-terraform project.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace\_name>' will be appended to the bucket name. | `string` | n/a | yes |
| findings\_data\_import\_lambda\_s3\_key | The key (name) of the zip file for the findings data import Lambda function inside the S3 bucket. | `string` | n/a | yes |
| findings\_data\_import\_ssm\_db\_name | The name of the parameter in AWS SSM that holds the name of the database to store the findings data in. | `string` | `""` | no |
| findings\_data\_import\_ssm\_db\_password | The name of the parameter in AWS SSM that holds the database password for the user with write permission to the findings database. | `string` | `""` | no |
| findings\_data\_import\_ssm\_db\_user | The name of the parameter in AWS SSM that holds the database username with write permission to the findings database. | `string` | `""` | no |
| findings\_data\_input\_suffix | The suffix used by files found in the findings\_data\_s3\_bucket that contain findings data. | `string` | n/a | yes |
| findings\_data\_s3\_bucket | The name of the bucket where the findings data JSON file can be found.  Note that in production Terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace\_name>' will be appended to the bucket name. | `string` | `""` | no |
| findings\_data\_save\_failed | Whether or not to save files for imports that have failed. | `bool` | `true` | no |
| findings\_data\_save\_succeeded | Whether or not to save files for imports that have succeeded. | `bool` | `false` | no |
| kevsync\_failure\_emails | A list of the emails to which alerts should be sent if KEV synchronization fails. | `list(string)` | ```[ "cyberdirectives@cisa.dhs.gov", "vulnerability@cisa.dhs.gov" ]``` | no |
| mgmt\_nessus\_activation\_codes | A list of strings containing Nessus activation codes used in the management VPC. | `list(string)` | n/a | yes |
| mgmt\_nessus\_instance\_count | The number of Nessus instances to create if a management environment is set to be created. | `number` | `1` | no |
| mongo\_disks | The data volumes for the mongo instance(s). | `map(string)` | ```{ "data": "/dev/xvdb", "journal": "/dev/xvdc", "log": "/dev/xvdd" }``` | no |
| mongo\_instance\_count | The number of Mongo instances to create. | `number` | `1` | no |
| nessus\_activation\_codes | A list of strings containing Nessus activation codes. | `list(string)` | n/a | yes |
| nessus\_cyhy\_runner\_disk | The cyhy-runner data volume for the Nessus instance(s). | `string` | `"/dev/xvdb"` | no |
| nessus\_instance\_count | The number of Nessus instances to create. | `number` | n/a | yes |
| nmap\_cyhy\_runner\_disk | The cyhy-runner data volume for the Nmap instance(s). | `string` | `"/dev/nvme1n1"` | no |
| nmap\_instance\_count | The number of Nmap instances to create. | `number` | n/a | yes |
| remote\_ssh\_user | The username to use when sshing to the EC2 instances. | `string` | n/a | yes |
| reporter\_mailer\_override\_filename | This file is used to add/override any Docker composition settings for cyhy-mailer for the reporter EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer. | `string` | `"docker-compose.cyhy.yml"` | no |
| ses\_aws\_region | The AWS region where SES is configured. | `string` | `"us-east-1"` | no |
| ses\_role\_arn | The ARN of the role that must be assumed in order to send emails. | `string` | n/a | yes |
| tags | Tags to apply to all AWS resources created. | `map(string)` | `{}` | no |
| trusted\_ingress\_networks\_ipv4 | IPv4 CIDR blocks from which to allow ingress to the bastion server. | `list(string)` | ```[ "0.0.0.0/0" ]``` | no |
| trusted\_ingress\_networks\_ipv6 | IPv6 CIDR blocks from which to allow ingress to the bastion server. | `list(string)` | ```[ "::/0" ]``` | no |

## Outputs ##

No outputs.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.

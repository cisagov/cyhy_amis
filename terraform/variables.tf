variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default = "a"
}

variable "tags" {
  type = "map"
  description = "Tags to apply to all AWS resources created"
  default = {}
}

variable "mongo_disks" {
  type = "map"
  default = {
    data = "/dev/xvdb"
    journal = "/dev/xvdc"
    log = "/dev/xvdd"
  }
}

variable "nmap_cyhy_runner_disk" {
  description = "The cyhy-runner data volume for the nmap instance(s)"
  default = "/dev/nvme1n1"
}

variable "nessus_cyhy_runner_disk" {
  description = "The cyhy-runner data volume for the nessus instance(s)"
  default = "/dev/xvdb"
}

# This should be overridden by a production.tfvars file,
# most likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  type = "list"
  description = "IPv4 CIDR blocks from which to allow ingress to the bastion server"
  default = [ "0.0.0.0/0" ]
}

variable "trusted_ingress_networks_ipv6" {
  type = "list"
  description = "IPv6 CIDR blocks from which to allow ingress to the bastion server"
  default = [ "::/0" ]
}

variable "remote_ssh_user" {
  description = "The username to use when sshing to the EC2 instances"
}

variable "nessus_activation_codes" {
  type = "list"
  description = "A list of strings containing Nessus activation codes"
}

variable "mgmt_nessus_activation_code" {
  description = "The Nessus activation code used in the management VPC"
  default = ""
}

variable "create_cyhy_flow_logs" {
  description = "Whether or not to create flow logs for the CyHy VPC.  Zero means no and one means yes"
  default = 0
}

variable "create_bod_flow_logs" {
  description = "Whether or not to create flow logs for the BOD 18-01 VPC.  Zero means no and one means yes"
  default = 0
}

variable "create_mgmt_flow_logs" {
  description = "Whether or not to create flow logs for the Management VPC.  Zero means no and one means yes"
  default = 0
}

variable "cyhy_archive_bucket_name" {
  description = "S3 bucket for storing compressed archive files created by cyhy-archive"
  default = "ncats-cyhy-archive"
}

variable "cyhy_elastic_ip_cidr_block" {
  description = "The CIDR block of elastic addresses available for use by CyHy scanner instances."
  default = ""
}

variable "cyhy_portscan_first_elastic_ip_offset" {
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy portscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first portscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional portscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  default = 0
}

variable "cyhy_vulnscan_first_elastic_ip_offset" {
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy vulnscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first vulnscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional vulnscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  default = 1
}

variable "bod_nat_gateway_eip" {
  description = "The IP corresponding to the EIP to be used for the BOD 18-01 NAT gateway in production.  In a non-production workspace an EIP will be created.."
  default = ""
}

variable "scan_types" {
  type = "list"
  description = "The scan types that can be run."
}

variable "lambda_function_names" {
  type = "map"
  description = "The names to use for the Lambda functions.  The keys are the values in scan_types."
}

variable "lambda_function_bucket" {
  type = "string"
  description = "The name of the S3 bucket where the Lambda function zip files reside.  Terraform cannot access buckets that are not in the provider's region, so the region name will be appended to the bucket name to obtain the actual bucket where the zips are stored.  So if we are working in region us-west-1 and this variable has the value buckethead, then the zips will be looked for in the bucket buckethead-us-west-1."
}

variable "lambda_function_keys" {
  type = "map"
  description = "The keys (names) of the zip files for the Lambda functions inside the S3 bucket.  The keys for the map are the values in scan_types."
}

variable "dmarc_import_aws_region" {
  description = "The AWS region where the dmarc-import Elasticsearch database resides."
  default = "us-east-1"
}

variable "dmarc_import_es_arn" {
  description = "The ARN of the dmarc-import Elasticsearch database."
}

variable "ses_aws_region" {
  description = "The AWS region where SES is configured."
  default = "us-east-1"
}

# If additional VPCs are added in the future:
#  - Ensure that they include security groups and ACLs that allow complete
#    access by the vulnscanner in the management VPC
#  - Ensure that the variable below is used to enable/disable the security
#    group and ACL rules as needed
#
# For some examples of this, refer to the rules in these files:
#  - cyhy_private_security_group_rules.tf
#  - cyhy_private_acl_rules.tf
variable "enable_mgmt_vpc_access_to_all_vpcs" {
  description = "Whether or not to enable unfettered access from the vulnerability scanner in the Management VPC to other VPCs (CyHy, BOD).  This should only be enabled while running security scans from the Management VPC.  Zero means access is disabled and one means access is enabled."
  default = 0
}

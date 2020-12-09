variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default     = "a"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all AWS resources created"
  default     = {}
}

variable "mongo_disks" {
  type = map(string)
  default = {
    data    = "/dev/xvdb"
    journal = "/dev/xvdc"
    log     = "/dev/xvdd"
  }
}

variable "nmap_cyhy_runner_disk" {
  description = "The cyhy-runner data volume for the nmap instance(s)"
  default     = "/dev/nvme1n1"
}

variable "nessus_cyhy_runner_disk" {
  description = "The cyhy-runner data volume for the nessus instance(s)"
  default     = "/dev/xvdb"
}

# This should be overridden by a production.tfvars file,
# most likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  type        = list(string)
  description = "IPv4 CIDR blocks from which to allow ingress to the bastion server"
  default     = ["0.0.0.0/0"]
}

variable "trusted_ingress_networks_ipv6" {
  type        = list(string)
  description = "IPv6 CIDR blocks from which to allow ingress to the bastion server"
  default     = ["::/0"]
}

variable "remote_ssh_user" {
  description = "The username to use when sshing to the EC2 instances"
}

variable "nessus_activation_codes" {
  type        = list(string)
  description = "A list of strings containing Nessus activation codes"
}

variable "mgmt_nessus_activation_codes" {
  type        = list(string)
  description = "A list of strings containing Nessus activation codes used in the management VPC"
}

variable "create_cyhy_flow_logs" {
  type        = bool
  description = "Whether or not to create flow logs for the CyHy VPC."
  default     = false
}

variable "create_bod_flow_logs" {
  type        = bool
  description = "Whether or not to create flow logs for the BOD 18-01 VPC."
  default     = false
}

variable "create_mgmt_flow_logs" {
  type        = bool
  description = "Whether or not to create flow logs for the Management VPC."
  default     = false
}

variable "cyhy_archive_bucket_name" {
  description = "S3 bucket for storing compressed archive files created by cyhy-archive"
  default     = "ncats-cyhy-archive"
}

variable "cyhy_elastic_ip_cidr_block" {
  description = "The CIDR block of elastic addresses available for use by CyHy scanner instances."
  default     = ""
}

variable "cyhy_portscan_first_elastic_ip_offset" {
  type        = number
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy portscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first portscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional portscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  default     = 0
}

variable "cyhy_vulnscan_first_elastic_ip_offset" {
  type        = number
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy vulnscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first vulnscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional vulnscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  default     = 1
}

variable "bod_nat_gateway_eip" {
  description = "The IP corresponding to the EIP to be used for the BOD 18-01 NAT gateway in production.  In a non-production workspace an EIP will be created.."
  default     = ""
}

variable "scan_types" {
  type        = list(string)
  description = "The scan types that can be run."
}

variable "lambda_function_names" {
  type        = map(string)
  description = "The names to use for the Lambda functions.  The keys are the values in scan_types."
}

variable "lambda_function_bucket" {
  type        = string
  description = "The name of the S3 bucket where the Lambda function zip files reside.  Terraform cannot access buckets that are not in the provider's region, so the region name will be appended to the bucket name to obtain the actual bucket where the zips are stored.  So if we are working in region us-west-1 and this variable has the value buckethead, then the zips will be looked for in the bucket buckethead-us-west-1."
}

variable "lambda_function_keys" {
  type        = map(string)
  description = "The keys (names) of the zip files for the Lambda functions inside the S3 bucket.  The keys for the map are the values in scan_types."
}

variable "dmarc_import_aws_region" {
  description = "The AWS region where the dmarc-import Elasticsearch database resides."
  default     = "us-east-1"
}

variable "dmarc_import_es_role_arn" {
  type        = string
  description = "The ARN of the role that must be assumed in order to read the dmarc-import Elasticsearch database."
}

variable "ses_aws_region" {
  description = "The AWS region where SES is configured."
  default     = "us-east-1"
}

variable "ses_role_arn" {
  type        = string
  description = "The ARN of the role that must be assumed in order to send emails."
}

variable "reporter_mailer_override_filename" {
  description = "This file is used to add/override any docker-compose settings for cyhy-mailer for the reporter EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer."
  default     = "docker-compose.cyhy.yml"
}

variable "docker_mailer_override_filename" {
  description = "This file is used to add/override any docker-compose settings for cyhy-mailer for the docker EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer."
  default     = "docker-compose.bod.yml"
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
variable "enable_mgmt_vpc" {
  type        = bool
  description = "Whether or not to enable unfettered access from the vulnerability scanner in the Management VPC to other VPCs (CyHy, BOD).  This should only be enabled while running security scans from the Management VPC."
  default     = false
}

variable "assessment_data_s3_bucket" {
  type        = string
  description = "The name of the bucket where the assessment data JSON file can be found.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  default     = ""
}

variable "assessment_data_filename" {
  type        = string
  description = "The name of the assessment data JSON file that can be found in the assessment_data_s3_bucket."
}

variable "assessment_data_import_lambda_s3_bucket" {
  type        = string
  description = "The name of the bucket where the assessment data import Lambda function can be found.  This bucket should be created with https://github.com/cisagov/assessment-data-import-terraform.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
}

variable "assessment_data_import_lambda_s3_key" {
  type        = string
  description = "The key (name) of the zip file for the assessment data import Lambda function inside the S3 bucket."
}

variable "assessment_data_import_db_hostname" {
  type        = string
  description = "The hostname that has the database to store the assessment data in."
  default     = ""
}

variable "assessment_data_import_db_port" {
  type        = string
  description = "The port that the database server is listening on."
  default     = ""
}

variable "assessment_data_import_ssm_db_name" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the name of the database to store the assessment data in."
  default     = ""
}

variable "assessment_data_import_ssm_db_user" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the database username with write permission to the assessment database."
  default     = ""
}

variable "assessment_data_import_ssm_db_password" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the database password for the user with write permission to the assessment database."
  default     = ""
}

variable "findings_data_s3_bucket" {
  type        = string
  description = "The name of the bucket where the findings data JSON file can be found.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  default     = ""
}

variable "findings_data_input_suffix" {
  type        = string
  description = "The suffix used by files found in the findings_data_s3_bucket that contain findings data."
}

variable "findings_data_field_map" {
  type        = string
  description = "The key for the file storing field name mappings in JSON format."
}

variable "findings_data_save_failed" {
  type        = bool
  description = "Whether or not to save files for imports that have failed."
  default     = true
}

variable "findings_data_save_succeeded" {
  type        = bool
  description = "Whether or not to save files for imports that have succeeded."
  default     = false
}

variable "findings_data_import_lambda_s3_bucket" {
  type        = string
  description = "The name of the bucket where the findings data import Lambda function can be found.  This bucket should be created with https://github.com/cisagov/findings-data-import-terraform.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
}

variable "findings_data_import_lambda_s3_key" {
  type        = string
  description = "The key (name) of the zip file for the findings data import Lambda function inside the S3 bucket."
}

variable "findings_data_import_db_hostname" {
  type        = string
  description = "The hostname that has the database to store the findings data in."
  default     = ""
}

variable "findings_data_import_db_port" {
  type        = string
  description = "The port that the database server is listening on."
  default     = ""
}

variable "findings_data_import_ssm_db_name" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the name of the database to store the findings data in."
  default     = ""
}

variable "findings_data_import_ssm_db_user" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the database username with write permission to the findings database."
  default     = ""
}

variable "findings_data_import_ssm_db_password" {
  type        = string
  description = "The name of the parameter in AWS SSM that holds the database password for the user with write permission to the findings database."
  default     = ""
}

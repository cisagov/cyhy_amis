# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

variable "assessment_data_filename" {
  description = "The name of the assessment data JSON file that can be found in the assessment_data_s3_bucket."
  type        = string
}

variable "assessment_data_import_lambda_s3_bucket" {
  description = "The name of the bucket where the assessment data import Lambda function can be found.  This bucket should be created with the cisagov/assessment-data-import-terraform project.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  type        = string
}

variable "assessment_data_import_lambda_s3_key" {
  description = "The key (name) of the zip file for the assessment data import Lambda function inside the S3 bucket."
  type        = string
}

variable "bod_lambda_function_bucket" {
  description = "The name of the S3 bucket where the Lambda function zip files reside.  Terraform cannot access buckets that are not in the provider's region, so the region name will be appended to the bucket name to obtain the actual bucket where the zips are stored.  So if we are working in region `us-west-1` and this variable has the value `buckethead`, then the zips will be looked for in the bucket `buckethead-us-west-1`."
  type        = string
}

variable "dmarc_import_es_role_arn" {
  description = "The ARN of the role that must be assumed in order to read the dmarc-import Elasticsearch database."
  type        = string
}

variable "findings_data_field_map" {
  description = "The key for the file storing field name mappings in JSON format."
  type        = string
}

variable "findings_data_import_lambda_s3_bucket" {
  description = "The name of the bucket where the findings data import Lambda function can be found.  This bucket should be created with the cisagov/findings-data-import-terraform project.  Note that in production terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  type        = string
}

variable "findings_data_import_lambda_s3_key" {
  description = "The key (name) of the zip file for the findings data import Lambda function inside the S3 bucket."
  type        = string
}

variable "findings_data_input_suffix" {
  description = "The suffix used by files found in the findings_data_s3_bucket that contain findings data."
  type        = string
}

variable "mgmt_nessus_activation_codes" {
  description = "A list of strings containing Nessus activation codes used in the management VPC."
  type        = list(string)
}

variable "nessus_activation_codes" {
  description = "A list of strings containing Nessus activation codes."
  type        = list(string)
}

variable "nessus_instance_count" {
  description = "The number of Nessus instances to create."
  type        = number
}

variable "nmap_instance_count" {
  description = "The number of Nmap instances to create."
  type        = number
}

variable "remote_ssh_user" {
  description = "The username to use when sshing to the EC2 instances."
  type        = string
}

variable "ses_role_arn" {
  description = "The ARN of the role that must be assumed in order to send emails."
  type        = string
}

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "ami_prefixes" {
  default = {
    bastion   = "cyhy",
    dashboard = "cyhy",
    docker    = "cyhy",
    mongo     = "cyhy",
    nessus    = "cyhy",
    nmap      = "cyhy",
    reporter  = "cyhy",
  }
  description = "An object whose keys are the types of Packer images (defined in the `packer/` directory in the root of the repository) and whose values are the prefix to use for the corresponding AMI. The default for all images is \"cyhy\"."
  type        = object({ bastion = string, dashboard = string, docker = string, mongo = string, nessus = string, nmap = string, reporter = string })
}

variable "assessment_data_import_db_hostname" {
  default     = ""
  description = "The hostname that has the database to store the assessment data in."
  type        = string
}

variable "assessment_data_import_db_port" {
  default     = ""
  description = "The port that the database server is listening on."
  type        = string
}

variable "assessment_data_import_lambda_description" {
  default     = "Lambda function for importing assessment data."
  description = "The description to associate with the assessment-data-import Lambda function."
  type        = string
}

variable "assessment_data_import_lambda_handler" {
  default     = "lambda_handler.handler"
  description = "The entrypoint for the assessment-data-import Lambda."
  type        = string
}

variable "assessment_data_import_ssm_db_name" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the name of the database to store the assessment data in."
  type        = string
}

variable "assessment_data_import_ssm_db_password" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the database password for the user with write permission to the assessment database."
  type        = string
}

variable "assessment_data_import_ssm_db_user" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the database username with write permission to the assessment database."
  type        = string
}

variable "assessment_data_s3_bucket" {
  default     = ""
  description = "The name of the bucket where the assessment data JSON file can be found.  Note that in production Terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  type        = string
}

variable "aws_availability_zone" {
  default     = "a"
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  type        = string
}

variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region to deploy into (e.g. us-east-1)."
  type        = string
}

variable "bod_lambda_functions" {
  default     = {}
  description = "A map of information for each BOD 18-01 Lambda. The keys are the scan types and the values are objects that contain the Lambda's name and the key (name) for the corresponding deployment package in the BOD Lambda S3 bucket. Example: `{ pshtt = { lambda_file = \"pshtt.zip\", lambda_name = \"task_pshtt\" }}`"
  type        = map(object({ lambda_file = string, lambda_name = string }))
}

variable "bod_nat_gateway_eip" {
  default     = ""
  description = "The IP corresponding to the EIP to be used for the BOD 18-01 NAT gateway in production.  In a non-production workspace an EIP will be created."
  type        = string
}

variable "cloudwatch_alarm_emails" {
  default = [
    "cisa-cool-group+cyhy@trio.dhs.gov",
  ]
  description = "A list of the emails to which alerts should be sent if any CloudWatch Alarm is triggered."
  type        = list(string)
}

variable "commander_config" {
  default = {
    jobs_per_nessus_host = 16
    jobs_per_nmap_host   = 8
    next_scan_limit      = 8192
  }
  description = "Configuration options for the CyHy commander's configuration file."
  type        = object({ jobs_per_nessus_host = number, jobs_per_nmap_host = number, next_scan_limit = number })
}

variable "create_bod_flow_logs" {
  default     = false
  description = "Whether or not to create flow logs for the BOD 18-01 VPC."
  type        = bool
}

variable "create_cyhy_flow_logs" {
  default     = false
  description = "Whether or not to create flow logs for the CyHy VPC."
  type        = bool
}

variable "create_mgmt_flow_logs" {
  default     = false
  description = "Whether or not to create flow logs for the Management VPC."
  type        = bool
}

variable "cyhy_archive_bucket_name" {
  default     = "ncats-cyhy-archive"
  description = "S3 bucket for storing compressed archive files created by cyhy-archive."
  type        = string
}

variable "cyhy_elastic_ip_cidr_block" {
  default     = ""
  description = "The CIDR block of elastic addresses available for use by CyHy scanner instances."
  type        = string
}

variable "cyhy_portscan_first_elastic_ip_offset" {
  default     = 0
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy portscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first portscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional portscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  type        = number
}

variable "cyhy_vulnscan_first_elastic_ip_offset" {
  default     = 1
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* CyHy vulnscan instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first vulnscan address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional vulnscan instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available."
  type        = number
}

variable "dmarc_import_aws_region" {
  default     = "us-east-1"
  description = "The AWS region where the dmarc-import Elasticsearch database resides."
  type        = string
}

variable "docker_mailer_override_filename" {
  default     = "docker-compose.bod.yml"
  description = "This file is used to add/override any Docker composition settings for cyhy-mailer for the docker EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer."
  type        = string
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
  default     = false
  description = "Whether or not to enable unfettered access from the vulnerability scanner in the Management VPC to other VPCs (CyHy, BOD).  This should only be enabled while running security scans from the Management VPC."
  type        = bool
}

variable "findings_data_import_db_hostname" {
  default     = ""
  description = "The hostname that has the database to store the findings data in."
  type        = string
}

variable "findings_data_import_db_port" {
  default     = ""
  description = "The port that the database server is listening on."
  type        = string
}

variable "findings_data_import_lambda_failure_emails" {
  default     = []
  description = "A list of the emails to which alerts should be sent if findings data processing fails."
  type        = list(string)
}


variable "findings_data_import_lambda_failure_prefix" {
  default     = "failed/"
  description = "The object prefix that findings JSONs that have failed to process successfully will have in the findings data bucket."
  type        = string
}

variable "findings_data_import_lambda_failure_suffix" {
  default     = ".json"
  description = "The object suffix that findings JSONs that have failed to process successfully will have in the findings data bucket."
  type        = string
}

variable "findings_data_import_lambda_description" {
  default     = "Lambda function for importing findings data."
  description = "The description to associate with the findings-data-import Lambda function."
  type        = string
}

variable "findings_data_import_lambda_handler" {
  default     = "lambda_handler.handler"
  description = "The entrypoint for the findings-data-import Lambda."
  type        = string
}

variable "findings_data_import_ssm_db_name" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the name of the database to store the findings data in."
  type        = string
}

variable "findings_data_import_ssm_db_password" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the database password for the user with write permission to the findings database."
  type        = string
}

variable "findings_data_import_ssm_db_user" {
  default     = ""
  description = "The name of the parameter in AWS SSM that holds the database username with write permission to the findings database."
  type        = string
}

variable "findings_data_s3_bucket" {
  default     = ""
  description = "The name of the bucket where the findings data JSON file can be found.  Note that in production Terraform workspaces, the string '-production' will be appended to the bucket name.  In non-production workspaces, '-<workspace_name>' will be appended to the bucket name."
  type        = string
}

variable "findings_data_save_failed" {
  default     = true
  description = "Whether or not to save files for imports that have failed."
  type        = bool
}

variable "findings_data_save_succeeded" {
  default     = false
  description = "Whether or not to save files for imports that have succeeded."
  type        = bool
}

variable "kevsync_failure_emails" {
  default = [
    "cyberdirectives@cisa.dhs.gov",
    "vulnerability@cisa.dhs.gov",
  ]
  description = "A list of the emails to which alerts should be sent if KEV synchronization fails."
  type        = list(string)
}

variable "mgmt_nessus_instance_count" {
  default     = 1
  description = "The number of Nessus instances to create if a management environment is set to be created."
  type        = number
}

variable "mongo_disks" {
  default = {
    data    = "/dev/xvdb"
    journal = "/dev/xvdc"
    log     = "/dev/xvdd"
  }
  description = "The data volumes for the mongo instance(s)."
  type        = map(string)
}

variable "mongo_instance_count" {
  default     = 1
  description = "The number of Mongo instances to create."
  type        = number
}

variable "nessus_cyhy_runner_disk" {
  default     = "/dev/xvdb"
  description = "The cyhy-runner data volume for the Nessus instance(s)."
  type        = string
}

variable "nmap_cyhy_runner_disk" {
  default     = "/dev/nvme1n1"
  description = "The cyhy-runner data volume for the Nmap instance(s)."
  type        = string
}

variable "reporter_mailer_override_filename" {
  default     = "docker-compose.cyhy.yml"
  description = "This file is used to add/override any Docker composition settings for cyhy-mailer for the reporter EC2 instance.  It must already exist in /var/cyhy/cyhy-mailer."
  type        = string
}

variable "ses_aws_region" {
  default     = "us-east-1"
  description = "The AWS region where SES is configured."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to apply to all AWS resources created."
  type        = map(string)
}

# This should be overridden by a production.tfvars file,
# most likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  default     = ["0.0.0.0/0"]
  description = "IPv4 CIDR blocks from which to allow ingress to the bastion server."
  type        = list(string)
}

variable "trusted_ingress_networks_ipv6" {
  default     = ["::/0"]
  description = "IPv6 CIDR blocks from which to allow ingress to the bastion server."
  type        = list(string)
}

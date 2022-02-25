# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

variable "nessus_activation_codes" {
  description = "A list of strings containing Nessus activation codes."
  type        = list(string)
}

variable "remote_ssh_user" {
  description = "The username to use when sshing to the EC2 instances."
  type        = string
}

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "aws_availability_zone" {
  default     = "a"
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  type        = string
}

# Currently we need to use us-east-1a because we are using a subnet in the
# default VPC, and that subnet resides in us-east-1a
variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region to deploy into (e.g. us-east-1)."
  type        = string
}

variable "cyhy_elastic_ip_cidr_block" {
  default     = ""
  description = "The CIDR block of elastic addresses available for use by CyHy scanner instances.  This is only used in production workspaces."
  type        = string
}

variable "nessus_first_elastic_ip_offset" {
  default     = 1
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* Nessus instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first Nessus address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional Nessus instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available.  This is only used in production workspaces."
  type        = number
}

variable "nessus_instance_count" {
  default     = 1
  description = "The number of Nessus instances to create."
  type        = number
}

variable "tags" {
  default = {
    Team        = "VM Fusion - Development"
    Application = "Manual Cyber Hygiene"
  }
  description = "Tags to apply to all AWS resources created."
  type        = map(string)
}

# This should be overridden by a production.tfvars file,
# most-likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  default     = ["0.0.0.0/0"]
  description = "Trusted IPv4 ingress networks."
  type        = list(string)
}

variable "trusted_ingress_networks_ipv6" {
  default     = ["::/0"]
  description = "Trusted IPv6 ingress networks."
  type        = list(string)
}

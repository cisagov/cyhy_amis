variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
  # Currently we need to use us-east-1a because we are using a subnet in the
  # default VPC, and that subnet resides in us-east-1a
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default     = "a"
}

variable "tags" {
  type = map(string)
  default = {
    Team        = "VM Fusion - Development"
    Application = "Manual Cyber Hygiene"
  }
  description = "Tags to apply to all AWS resources created"
}

# This should be overridden by a production.tfvars file,
# most-likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Trusted IPv4 ingress networks"
}

variable "trusted_ingress_networks_ipv6" {
  type        = list(string)
  default     = ["::/0"]
  description = "Trusted IPv6 ingress networks"
}

variable "remote_ssh_user" {
  description = "The username to use when sshing to the EC2 instances"
}

variable "nessus_instance_count" {
  type        = number
  description = "The number of Nessus instances to create."
  default     = 1
}

variable "nessus_activation_codes" {
  type        = list(string)
  description = "A list of strings containing Nessus activation codes"
}

variable "cyhy_elastic_ip_cidr_block" {
  description = "The CIDR block of elastic addresses available for use by CyHy scanner instances.  This is only used in Production workspaces."
  default     = ""
}

variable "nessus_first_elastic_ip_offset" {
  type        = number
  description = "The offset of the address (from the start of the elastic IP CIDR block) to be assigned to the *first* Nessus instance.  For example, if the CIDR block is 192.168.1.0/24 and the offset is set to 10, the first Nessus address used will be 192.168.1.10.  This is only used in production workspaces.  Each additional Nessus instance will get the next consecutive address in the block.  NOTE: This will only work as intended when a contiguous CIDR block of EIP addresses is available.  This is only used in Production workspaces."
  default     = 1
}

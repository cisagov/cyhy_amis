# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------
variable "ami_prefix" {
  default     = "cyhy"
  description = "The prefix to use for the names of AMIs created."
  type        = string
}

variable "ami_regions" {
  default = [
    "us-east-1",
    "us-west-1",
    "us-west-2",
  ]
  description = "The list of AWS regions to copy the AMI to once it has been created. Example: [\"us-east-1\"]"
  type        = list(string)
}

variable "build_region" {
  default     = "us-east-2"
  description = "The region in which to retrieve the base AMI from and build the new AMI."
  type        = string
}

variable "cyhy_user_information" {
  default = {
    home_directory = "/var/cyhy"
    ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOreUDnms12MPI0gh7K+YGaESYgC2TY1zA+kSK/g+n5+ cyhy"
    user_id        = "2048"
    username       = "cyhy"
  }
  description = "The user information for the Cyber Hygiene user."
  type = object({
    home_directory = string
    ssh_public_key = string
    user_id        = string
    username       = string
  })
}

variable "force_install_ansible_requirements" {
  default     = false
  description = "Indicate if the Ansible requirements should be force installed."
  type        = bool
}

variable "force_install_ansible_requirements_with_dependencies" {
  default     = false
  description = "Indicate if the Ansible requirements *and* their dependencies should be force installed."
  type        = bool
}

variable "is_prerelease" {
  default     = false
  description = "The pre-release status to use for the tags applied to the created AMI."
  type        = bool
}

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

variable "is_prerelease" {
  default     = false
  description = "The pre-release status to use for the tags applied to the created AMI."
  type        = bool
}

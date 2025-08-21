
terraform {
  # Version 1.1 of Terraform is the first version to support the
  # nullable key in variable definitions.
  required_version = "~> 1.1"

  # If you use any other providers you should also pin them to the
  # major version currently being used.  This practice will help us
  # avoid unwelcome surprises.
  required_providers {
    # We have verified that our code works with version 6.7 of this
    # Terraform provider.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.0"
    }

    # We have verified that our code works with version 3.2 of this
    # Terraform provider.
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}


terraform {
  # We want to hold off on 1.1 or higher until we have tested it.
  required_version = "~> 1.0"

  # If you use any other providers you should also pin them to the
  # major version currently being used.  This practice will help us
  # avoid unwelcome surprises.
  required_providers {
    # Version 3.62.0 of the Terraform AWS provider adds the
    # `stop_instance_before_detaching` argument to the `aws_volume_attachment`
    # resource.
    # https://github.com/hashicorp/terraform-provider-aws/pull/21144
    # https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md#3620-october-08-2021
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.38"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.0"
    }
  }
}

terraform {
  # We want to hold off on 1.1 or higher until we have tested it.
  required_version = "~> 1.0"

  # If you use any other providers you should also pin them to the
  # major version currently being used.  This practice will help us
  # avoid unwelcome surprises.
  required_providers {
    # Version 3.75.0 of the Terraform AWS provider backports the changes to how
    # AWS S3 resources are structured from the 4.0 release.
    # https://www.hashicorp.com/blog/terraform-aws-provider-4-0-refactors-s3-bucket-resource
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75"
    }
  }
}

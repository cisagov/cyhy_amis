terraform {
  # We want to hold off on 0.14 until we have tested it.
  required_version = "~> 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.1"
    }
  }
}

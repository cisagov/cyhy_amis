terraform {
  # We want to hold off on 0.14 until we have tested it.
  required_version = "~> 0.13.0"

  required_providers {
    aws     = "~> 3.0"
    archive = "~> 2.1"
  }
}

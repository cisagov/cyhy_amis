variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default = "us-east-2"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default = "a"
}

variable "tags" {
  type = "map"
  default = {
    Team = "NCATS OIS - Development"
    Application = "Manual Cyber Hygiene"
  }
  description = "Tags to apply to all AWS resources created"
}

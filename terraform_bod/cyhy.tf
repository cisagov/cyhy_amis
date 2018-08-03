# Find the CyHy VPC that is in the same workspace
data "aws_vpc" "cyhy_vpc" {
  filter {
    name = "tag:Name"
    values = [
      "CyHy"
    ]
  }

  filter {
    name = "tag:Application"
    values = [
      "Cyber Hygiene"
    ]
  }

  filter {
    name = "tag:Workspace"
    values = [
      "${terraform.workspace}"
    ]
  }
}

# Find the "CyHy Private" subnet that is in the same workspace
data "aws_subnet" "cyhy_private_subnet" {
  filter {
    name = "tag:Name"
    values = [
      "CyHy Private"
    ]
  }

  filter {
    name = "tag:Application"
    values = [
      "Cyber Hygiene"
    ]
  }

  filter {
    name = "tag:Workspace"
    values = [
      "${terraform.workspace}"
    ]
  }
}

# Find the "CyHy Private" security group that is in the same workspace
data "aws_security_group" "cyhy_private_sg" {
  filter {
    name = "tag:Name"
    values = [
      "CyHy Private"
    ]
  }

  filter {
    name = "tag:Application"
    values = [
      "Cyber Hygiene"
    ]
  }

  filter {
    name = "tag:Workspace"
    values = [
      "${terraform.workspace}"
    ]
  }
}

# Find the peering connection between this VPC and the BOD 18-01 VPC
data "aws_vpc_peering_connection" "peering_connection" {
  filter {
    name = "tag:Name"
    values = [
      "CyHy and BOD 18-01"
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

# Find the BOD 18-01 VPC that is in the same workspace
data "aws_vpc" "bod_vpc" {
  filter {
    name = "tag:Name"
    values = [
      "BOD 18-01"
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

# Find the "BOD 18-01 Private" subnet that is in the same workspace
data "aws_subnet" "bod_private_subnet" {
  filter {
    name = "tag:Name"
    values = [
      "BOD 18-01 Private"
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

# Find the "BOD 18-01 Docker" security group that is in the same
# workspace
data "aws_security_group" "bod_docker_sg" {
  filter {
    name = "tag:Name"
    values = [
      "BOD 18-01 Docker"
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

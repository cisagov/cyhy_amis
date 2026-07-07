data "amazon-ami" "debian_buster_x86_64" {
  filters = {
    name                = "debian-10-amd64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  # This allows for the use of deprecated AMIs, which is now necessary
  # for Debian Buster.
  include_deprecated = true
  most_recent        = true
  owners             = ["136693071363"]
  region             = var.build_region
}

data "amazon-ami" "debian_bookworm_arm64" {
  filters = {
    name                = "debian-12-arm64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

data "amazon-ami" "debian_bookworm_x86_64" {
  filters = {
    name                = "debian-12-amd64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

data "amazon-ami" "debian_trixie_arm64" {
  filters = {
    name                = "debian-13-arm64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

data "amazon-ami" "debian_trixie_x86_64" {
  filters = {
    name                = "debian-13-amd64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

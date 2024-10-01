packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.2"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
  # The required_plugins section is only supported in Packer 1.7.0 and
  # later.  We also want to avoid jumping to Packer v2 until we are
  # ready.
  required_version = "~> 1.7"
}

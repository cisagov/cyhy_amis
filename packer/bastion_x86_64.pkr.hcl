source "amazon-ebs" "bastion_x86_64" {
  ami_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  ami_name      = "${var.ami_prefix}-bastion-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions   = var.ami_regions
  instance_type = "t3.small"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  region       = var.build_region
  source_ami   = data.amazon-ami.debian_bookworm_x86_64.id
  ssh_username = "admin"
  tags = {
    Application   = "Cyber Hygiene"
    Architecture  = "x86_64"
    Base_AMI_Name = data.amazon-ami.debian_bookworm_x86_64.name
    OS_Version    = "Debian Bookworm"
    Pre_Release   = var.is_prerelease
    Release       = "Latest"
    Team          = "VM Fusion - Development"
  }
  temporary_key_pair_type = "ed25519"
}

source "amazon-ebs" "reporter" {
  ami_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 10
    volume_type           = "gp3"
  }
  ami_name      = "${var.ami_prefix}-reporter-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions   = var.ami_regions
  instance_type = "t3.medium"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 10
    volume_type           = "gp3"
  }
  region       = var.build_region
  source_ami   = data.amazon-ami.debian_buster.id
  ssh_username = "admin"
  tags = {
    Application   = "Cyber Hygiene"
    Architecture  = "x86_64"
    Base_AMI_Name = data.amazon-ami.debian_buster.name
    OS_Version    = "Debian Buster"
    Pre_Release   = var.is_prerelease
    Release       = "Latest"
    Team          = "VM Fusion - Development"
  }
  temporary_key_pair_type = "ed25519"
}

build {
  sources = ["source.amazon-ebs.reporter"]

  provisioner "ansible" {
    groups        = ["reporter"]
    playbook_file = "ansible/upgrade.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    groups        = ["reporter"]
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    groups           = ["cyhy_reporter"]
    playbook_file    = "ansible/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }
}

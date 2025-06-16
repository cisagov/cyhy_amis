build {
  sources = ["source.amazon-ebs.nmap_x86_64"]

  provisioner "ansible" {
    galaxy_file            = "ansible/requirements.yml"
    galaxy_force_install   = var.force_install_ansible_requirements
    galaxy_force_with_deps = var.force_install_ansible_requirements_with_dependencies
    groups                 = ["nmap"]
    playbook_file          = "ansible/upgrade.yml"
    use_proxy              = false
    use_sftp               = true
  }

  provisioner "ansible" {
    groups        = ["nmap"]
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    groups           = ["nmap"]
    playbook_file    = "ansible/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }
}

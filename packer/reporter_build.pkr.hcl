build {
  sources = ["source.amazon-ebs.reporter_x86_64"]

  provisioner "ansible" {
    galaxy_file            = "ansible/requirements.yml"
    galaxy_force_install   = var.force_install_ansible_requirements
    galaxy_force_with_deps = var.force_install_ansible_requirements_with_dependencies
    groups                 = ["reporter"]
    playbook_file          = "ansible/upgrade.yml"
    use_proxy              = false
    use_sftp               = true
  }

  provisioner "ansible" {
    groups        = ["reporter"]
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    # Create the list of variables to pass to Ansible. We create a list of
    # arguments with preceding `--extra-vars` and then flatten it to ensure
    # that it is a single list of arguments.
    extra_arguments = flatten(setproduct(["--extra-vars"], [
      "cyhy_user_home_directory=${var.cyhy_user_information.home_directory}",
      # Since the SSH public key has spaces in it, we need to ensure it is quoted.
      format("cyhy_user_ssh_public_key=%q", var.cyhy_user_information.ssh_public_key),
      "cyhy_user_username=${var.cyhy_user_information.username}",
      "cyhy_user_uid=${var.cyhy_user_information.user_id}",
      "maxmind_account_id_secret=${data.amazon-parameterstore.maxmind_account_id.value}",
      "maxmind_license_key_secret=${data.amazon-parameterstore.maxmind_license_key.value}",
    ]))
    groups        = ["cyhy_reporter"]
    playbook_file = "ansible/playbook.yml"
    use_proxy     = false
    use_sftp      = true
  }
}

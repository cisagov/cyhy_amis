build {
  sources = ["source.amazon-ebs.docker_x86_64"]

  provisioner "ansible" {
    galaxy_file            = "ansible/requirements.yml"
    galaxy_force_install   = var.force_install_ansible_requirements
    galaxy_force_with_deps = var.force_install_ansible_requirements_with_dependencies
    groups                 = ["docker"]
    playbook_file          = "ansible/upgrade.yml"
    use_proxy              = false
    use_sftp               = true
  }

  provisioner "ansible" {
    groups        = ["docker"]
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    # Create the list of variables to pass to Ansible. We create a list of
    # arguments with preceding `--extra-vars` and then flatten it to ensure
    # that it is a single list of arguments. This will result in a list like:
    # [
    #   "--extra-vars",
    #   "foo=bar",
    #   "--extra-vars",
    #   "ham=eggs",
    # ]
    extra_arguments = flatten(setproduct(["--extra-vars"], concat(
      local.cyhy_user_ansible_variables,
    )))
    groups        = ["bod", "code_gov", "vdp_scan"]
    playbook_file = "ansible/playbook.yml"
    use_proxy     = false
    use_sftp      = true
  }
}

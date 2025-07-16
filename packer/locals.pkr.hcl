locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  cyhy_user_ansible_variables = [
    "cyhy_user_home_directory=${var.cyhy_user_information.home_directory}",
    # Since the SSH public key has spaces in it, we need to ensure it is quoted.
    format("cyhy_user_ssh_public_key=%q", var.cyhy_user_information.ssh_public_key),
    "cyhy_user_username=${var.cyhy_user_information.username}",
    "cyhy_user_uid=${var.cyhy_user_information.user_id}",
  ]

  maxmind_account_ansible_variables = [
    "maxmind_account_id_secret=${data.amazon-parameterstore.maxmind_account_id.value}",
    "maxmind_license_key_secret=${data.amazon-parameterstore.maxmind_license_key.value}",
  ]
}

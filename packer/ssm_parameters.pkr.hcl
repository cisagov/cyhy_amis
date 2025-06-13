data "amazon-parameterstore" "maxmind_account_id" {
  name            = var.maxmind_ssm_parameter_names.account_id
  with_decryption = true
}

data "amazon-parameterstore" "maxmind_license_key" {
  name            = var.maxmind_ssm_parameter_names.license_key
  with_decryption = true
}

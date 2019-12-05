variable "mgmt_bastion_public_ip" {}
variable "mgmt_nessus_private_ips" { type = list(string) }
variable "mgmt_nessus_activation_codes" { type = list(string) }
variable "remote_ssh_user" {}

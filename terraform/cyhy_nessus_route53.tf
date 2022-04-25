# Public DNS records
resource "aws_route53_record" "cyhy_nessus_pub_A" {
  count    = var.nessus_instance_count
  provider = aws.public_dns

  zone_id = data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.id
  name    = format("vulnscan%d.%s%s%s", count.index + 1, local.production_workspace ? "" : "${terraform.workspace}.", local.cyhy_public_subdomain, data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.name)
  type    = "A"
  ttl     = 30
  records = [
    local.nessus_public_ips[count.index].public_ip,
  ]
}

resource "null_resource" "cyhy_nessus_pub_PTR" {
  count = var.nessus_instance_count

  triggers = {
    eip_a_record      = aws_route53_record.cyhy_nessus_pub_A[count.index].name
    eip_allocation_id = local.nessus_public_ips[count.index].id
    region            = var.aws_region,
  }

  # Set up a corresponding PTR record for the EIP once the A record has been
  # created, then loop until the PTR record creation has been verified.
  provisioner "local-exec" {
    command = "aws --region ${self.triggers.region} ec2 modify-address-attribute --allocation-id ${self.triggers.eip_allocation_id} --domain-name ${self.triggers.eip_a_record} && until aws --region ${self.triggers.region} ec2 describe-addresses-attribute --allocation-id ${self.triggers.eip_allocation_id} --attribute domain-name | grep PtrRecord | grep --quiet ${self.triggers.eip_a_record}; do sleep 5s; done"
  }

  # The PTR records we create for the EIP need to be destroyed at some point,
  # and when we destroy the association between an EIP and an instance seems
  # like a suitable time to do so.
  provisioner "local-exec" {
    when    = destroy
    command = "aws --region ${self.triggers.region} ec2 reset-address-attribute --allocation-id ${self.triggers.eip_allocation_id} --attribute domain-name && until aws --region ${self.triggers.region} ec2 describe-addresses-attribute --allocation-id ${self.triggers.eip_allocation_id} --attribute domain-name | grep --quiet '\"Addresses\": \\[\\]'; do sleep 5s; done"
  }
}

# Private DNS records
resource "aws_route53_record" "cyhy_vulnscan_A" {
  count   = local.count_vuln_scanner
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.cyhy_nessus[count.index].private_ip,
  ]
}

resource "aws_route53_record" "cyhy_rev_vulnscan_PTR" {
  count   = local.count_vuln_scanner
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      3,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      2,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      1,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      0,
    ),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}",
  ]
}

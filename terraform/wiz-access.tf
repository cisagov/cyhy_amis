# ------------------------------------------------------------------------------
# Create a role and policies that can be used to connect an AWS account with the
# Wiz Cloud Security Platform.
# ------------------------------------------------------------------------------

module "wiz" {
  source = "https://wizio-public-fedramp.s3-us-gov-west-1.amazonaws.com/deployment-v3/aws/terraform/2209/wiz-aws-native-terraform-terraform-module.zip"

  cloud-cost-scanning       = false
  data-scanning             = true
  eks-scanning              = true
  external-id               = var.wiz_external_id
  lightsail-scanning        = true
  remote-arn                = var.wiz_remote_arn
  terraform-bucket-scanning = true
}

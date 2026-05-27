# ------------------------------------------------------------------------------
# Create a role and policies that can be used to connect an AWS account with the
# Wiz Cloud Security Platform.
# ------------------------------------------------------------------------------

module "wiz" {
  source  = "tf.app.wiz.io/wiz/native-terraform/aws"
  version = "~> 1.0"

  cloud-cost-scanning       = false
  data-scanning             = true
  eks-scanning              = true
  external-id               = var.wiz_external_id
  lightsail-scanning        = true
  remote-arn                = var.wiz_remote_arn
  terraform-bucket-scanning = true
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "ncats-terraform-state-storage" # Raytheon

    #bucket = "ncats-terraform-remote-state-storage" # DLT
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-1"
    key            = "route_53/terraform.tfstate"
  }
}

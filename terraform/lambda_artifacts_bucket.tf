# The S3 bucket where Lambda function deployment artifacts are stored
# Terraform code for this bucket is in:
#   https://github.com/cisagov/cyhy-lambda-bucket-terraform
data "aws_s3_bucket" "lambda_deployment_artifacts" {
  bucket = format("%s-%s", var.lambda_artifacts_bucket, local.production_workspace ? "production" : terraform.workspace)
}

resource "aws_s3_bucket" "create_moe_bucket" {
  bucket = "ncats-moe-data"
  acl    = "private"

  tags {
    Name        = "Moe bucket"
    Environment = "Dev"
  }
}

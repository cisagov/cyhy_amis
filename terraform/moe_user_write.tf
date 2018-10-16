resource "aws_iam_user" "create_moe_user_write" {
  name = "moe_user_write"
  path = "/system/"
}

resource "aws_iam_access_key" "create_moe_user_write" {
  user = "${aws_iam_user.create_moe_user_write.name}"
}

resource "aws_iam_user_policy" "create_moe_user_write_role" {
  name = "moe_bucket_write_access"
  user = "${aws_iam_user.create_moe_user_write.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::ncats-moe-data"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::ncats-moe-data/*"
            ]
        }
    ]
}
EOF
}

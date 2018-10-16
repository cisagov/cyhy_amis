resource "aws_iam_user" "create_moe_user_read" {
  name = "moe_user_read"
  path = "/system/"
}

resource "aws_iam_access_key" "create_moe_user_read" {
  user = "${aws_iam_user.create_moe_user_read.name}"
}

resource "aws_iam_user_policy" "create_moe_user_read" {
  name = "moe_bucket_read_access"
  user = "${aws_iam_user.create_moe_user_read.name}"

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

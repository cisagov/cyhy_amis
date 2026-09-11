resource "aws_dlm_lifecycle_policy" "cyhy_ebs" {
  description        = "Policy to generate twice-daily EBS snapshots for CyHy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  tags = {
    Name = "Generate twice-daily EBS snapshots for CyHy"
  }

  policy_details {
    policy_language = "STANDARD"
    resource_types  = ["VOLUME"]
    target_tags = {
      Application = "Cyber Hygiene"
    }

    schedule {
      copy_tags = true
      name      = "10 twice-daily snapshots"

      create_rule {
        interval      = 12
        interval_unit = "HOURS"
        times         = ["09:00"]
      }

      retain_rule {
        count = 10
      }
    }
  }
}

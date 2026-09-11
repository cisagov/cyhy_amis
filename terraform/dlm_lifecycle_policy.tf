resource "aws_dlm_lifecycle_policy" "cyhy_ebs" {
  description        = "Policy to generate EBS snapshots for CyHy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  tags = {
    Name = "EBS snapshots for CyHy"
  }

  policy_details {
    policy_language = "STANDARD"
    resource_types  = ["VOLUME"]
    target_tags = {
      Application = "Cyber Hygiene"
    }

    schedule {
      copy_tags = true
      name      = "CyHy EBS snapshots"

      create_rule {
        interval = var.ebs_volume_snapshot_create_interval
        times    = [var.ebs_volume_snapshot_evaluate_time]
      }

      retain_rule {
        count = var.ebs_volume_snapshot_retain_count
      }
    }
  }
}

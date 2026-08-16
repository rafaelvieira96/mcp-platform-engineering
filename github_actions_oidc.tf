data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint,
  ]
}

resource "aws_iam_role" "gh_actions_terraform_plan" {
  name                 = "gh-actions-terraform-plan"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsOIDCEnvironmentGate"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        # Since 2026-07-15 GitHub issues immutable subject claims for repos
        # created after that date: "repo:OWNER@OWNER_ID/REPO@REPO_ID:...".
        # Pinning to the literal owner_id/repo_id (rather than StringLike
        # with a wildcard) keeps this immune to repo/org rename or
        # ownership-recycling attacks, per GitHub's own guidance.
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:rafaelvieira96@19826939/mcp-platform-engineering@1332323772:environment:aws-plan"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "terraform_plan_s3_read_only" {
  name = "terraform-plan-s3-read-only"
  role = aws_iam_role.gh_actions_terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformPlanS3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:ListBucket",
        ]
        Resource = aws_s3_bucket.this.arn
      }
    ]
  })
}

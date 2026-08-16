locals {
  # aws_s3_bucket's Read() probes this full set of bucket attributes
  # regardless of which dedicated sub-resources (versioning, lifecycle,
  # etc.) are actually declared against the bucket, so terraform plan
  # needs all of these on every bucket it refreshes, not just the ones
  # matching declared sub-resources.
  s3_bucket_metadata_read_actions = [
    "s3:GetAccelerateConfiguration",
    "s3:GetBucketAcl",
    "s3:GetBucketCORS",
    "s3:GetBucketLocation",
    "s3:GetBucketLogging",
    "s3:GetBucketObjectLockConfiguration",
    "s3:GetBucketPolicy",
    "s3:GetBucketPublicAccessBlock",
    "s3:GetBucketRequestPayment",
    "s3:GetBucketTagging",
    "s3:GetBucketVersioning",
    "s3:GetBucketWebsite",
    "s3:GetEncryptionConfiguration",
    "s3:GetLifecycleConfiguration",
    "s3:GetReplicationConfiguration",
    "s3:ListBucket",
  ]
}

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
        Sid      = "TerraformPlanS3ReadOnly"
        Effect   = "Allow"
        Action   = local.s3_bucket_metadata_read_actions
        Resource = aws_s3_bucket.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "terraform_plan_state_read_only" {
  name = "terraform-plan-state-read-only"
  role = aws_iam_role.gh_actions_terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # terraform plan refreshes every resource declared against this
        # bucket (aws_s3_bucket + its versioning/encryption/ownership/
        # public-access-block/lifecycle/policy sub-resources in
        # state_backend.tf), so this mirrors the read actions each of
        # those resource types' AWS provider Read() calls.
        Sid    = "TerraformPlanStateBucketReadOnly"
        Effect = "Allow"
        # Adds GetBucketOwnershipControls on top of the shared bucket
        # metadata actions, for aws_s3_bucket_ownership_controls.terraform_state
        # (the app bucket has no equivalent resource).
        Action   = concat(local.s3_bucket_metadata_read_actions, ["s3:GetBucketOwnershipControls"])
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "TerraformPlanStateObjectReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        # terraform plan -lock=false never touches the lockfile object, so
        # this is scoped to the state object itself, not the whole bucket.
        Resource = "${aws_s3_bucket.terraform_state.arn}/mcp-platform-engineering/terraform.tfstate"
      }
    ]
  })
}

resource "aws_iam_role_policy" "terraform_plan_iam_self_read_only" {
  name = "terraform-plan-iam-self-read-only"
  role = aws_iam_role.gh_actions_terraform_plan.id

  # terraform plan refreshes every resource in the config, including the
  # OIDC provider, role, and inline policies this role itself is defined
  # by — so the role needs read access to its own IAM resources.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "TerraformPlanOIDCProviderReadOnly"
        Effect   = "Allow"
        Action   = "iam:GetOpenIDConnectProvider"
        Resource = aws_iam_openid_connect_provider.github_actions.arn
      },
      {
        Sid    = "TerraformPlanRoleReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
        ]
        Resource = aws_iam_role.gh_actions_terraform_plan.arn
      }
    ]
  })
}

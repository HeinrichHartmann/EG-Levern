# =============================================================================
# IAM -- a dedicated user for this premise (EG-Levern). Originally scoped to
# exactly what the dev certificate and its DNS records need; now also holds
# the site-deploy permissions `make deploy` / `make deploy-dev` /
# `make diff` / `make diff-dev` use, by Heinrich's explicit choice (SIG-9,
# 2026-11-25) over creating a fourth identity or widening hh.com.
#
# hh.com is denied acm:RequestCertificate and all route53:*, and stays that
# way: hh.com runs unattended deploys, and a principal that can request
# certificates and change DNS for eg-levern.de is one step away from a
# principal that could escalate to full account control, if it or anything
# using its credentials ever also held iam:CreateRole / iam:PutRolePolicy.
# Widening hh.com's policy, or routing through hh.com via sts:AssumeRole,
# both mean sharing this capability with whatever already holds hh.com's
# credentials (unattended deploys, any agent that runs them). So this
# premise keeps its own standing identity for DNS and certificates, rather
# than folding that into hh.com.
#
# Accepted tradeoff: this identity is now also the deploy credential, so a
# single compromised key can both reroute DNS/certs *and* overwrite the
# live site content -- deploy is no longer isolated from the DNS/cert
# escalation path the way it was before. It remains isolated from IAM
# administration: nothing below touches iam:*, so this user can never
# widen its own policy or create another one.
#
# Applying this configuration is IAM administration: it requires Heinrich's
# own privileged AWS identity, never hh.com's credentials and not anything
# an agent holds. `../scripts/with-bw-admin.sh` runs a command with that
# identity pulled from Bitwarden so it never lands in a file on disk.
#
# The user's access key is deliberately NOT managed here -- see README.md,
# "The access key is not in OpenTofu".
# =============================================================================

# -----------------------------------------------------------------------------
# Imports -- the user and its policy already exist
#
# Both were created before this module was split out of ../, so they exist in
# AWS but not in this state file. Importing needs iam:GetUser, which neither
# hh.com nor the automation user itself has (verified: both get AccessDenied),
# so it only resolves on Heinrich's first run with his own identity.
#
# These are `import` blocks rather than README instructions to run `tofu
# import` by hand so that first run is a plain `tofu apply`: no resource
# addresses or import IDs to retype, and no chance of an apply failing with
# EntityAlreadyExists because the import step was skipped. Same pattern as
# ../prod.tf. They are inert once the resources are in state.
# -----------------------------------------------------------------------------

import {
  to = aws_iam_user.dev_infra_automation
  id = "eg-levern-dev-infra-automation"
}

import {
  to = aws_iam_user_policy.dev_infra_automation
  id = "eg-levern-dev-infra-automation:dev-certificate-and-dns"
}

resource "aws_iam_user" "dev_infra_automation" {
  name = "eg-levern-dev-infra-automation"

  tags = {
    Premise = "eg-levern"
  }
}

resource "aws_iam_user_policy" "dev_infra_automation" {
  name = "dev-certificate-and-dns"
  user = aws_iam_user.dev_infra_automation.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # CloudFront only accepts certificates from us-east-1, and ACM has
        # no certificate ARN to scope to before the certificate exists, so
        # this is restricted by region instead.
        Sid    = "DevCertificateLifecycle"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate",
          "acm:ListTagsForCertificate",
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:RequestedRegion" = "us-east-1" }
        }
      },
      {
        # route53:ListHostedZones has no resource-level permissions at all
        # -- AWS requires Resource = "*" for it. Everything that actually
        # reads or writes records is scoped to one zone below.
        Sid      = "ListHostedZones"
        Effect   = "Allow"
        Action   = "route53:ListHostedZones"
        Resource = "*"
      },
      {
        Sid    = "EgLevernZoneRecords"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.eg_levern_hosted_zone_id}"
      },
      {
        # What `aws s3 cp ./public s3://...` needs, scoped to exactly the
        # two site buckets -- not every bucket in the account.
        Sid    = "DeploySiteContent"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.prod_bucket_name}",
          "arn:aws:s3:::${var.prod_bucket_name}/*",
          "arn:aws:s3:::${var.dev_bucket_name}",
          "arn:aws:s3:::${var.dev_bucket_name}/*",
        ]
      },
      {
        # What `aws cloudfront create-invalidation` needs after a deploy,
        # scoped to the two site distributions.
        Sid    = "DeployCacheInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
        ]
        Resource = [
          "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.prod_distribution_id}",
          "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.dev_distribution_id}",
        ]
      },
    ]
  })
}

output "dev_infra_automation_user_arn" {
  description = "ARN of the dedicated eg-levern-dev-infra-automation user."
  value       = aws_iam_user.dev_infra_automation.arn
}

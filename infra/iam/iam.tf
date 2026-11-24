# =============================================================================
# IAM -- a dedicated user for this premise (EG-Levern), scoped to exactly
# what the dev certificate and its DNS records need.
#
# hh.com is denied acm:RequestCertificate and all route53:*, and stays that
# way: hh.com runs unattended deploys, and a principal that can request
# certificates and change DNS for eg-levern.de is one step away from a
# principal that could escalate to full account control, if it or anything
# using its credentials ever also held iam:CreateRole / iam:PutRolePolicy.
# Widening hh.com's policy, or routing through hh.com via sts:AssumeRole,
# both mean sharing this capability with whatever already holds hh.com's
# credentials (unattended deploys, any agent that runs them). Instead this
# premise gets its own standing identity, used for nothing else, so the
# permissions below never have to be shared with a broader-purpose
# principal.
#
# Applying this configuration is IAM administration: it requires Heinrich's
# own privileged AWS identity, never hh.com's credentials and not anything
# an agent holds. `../scripts/with-bw-admin.sh` runs a command with that
# identity pulled from Bitwarden so it never lands in a file on disk.
#
# The user's access key is deliberately NOT managed here -- see README.md,
# "The access key is not in OpenTofu".
# =============================================================================

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
    ]
  })
}

output "dev_infra_automation_user_arn" {
  description = "ARN of the dedicated eg-levern-dev-infra-automation user."
  value       = aws_iam_user.dev_infra_automation.arn
}

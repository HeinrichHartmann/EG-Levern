# =============================================================================
# IAM -- a narrowly-scoped role so the deploy user never holds ACM/Route 53
# permissions directly
#
# hh.com is already denied acm:RequestCertificate and all route53:* (see
# README.md). The fix is not to widen hh.com's own policy with those
# actions: hh.com runs unattended deploys, and a principal that can request
# certificates and change DNS for eg-levern.de is one step away from a
# principal that could escalate to full account control, if it or anything
# using its credentials ever also held iam:CreateRole / iam:PutRolePolicy.
# This configuration deliberately never asks for that permission, and it
# should never be granted to hh.com by hand either.
#
# Instead: a role scoped to exactly what OpenTofu needs for the dev
# certificate and its DNS records, which hh.com may reach only via
# sts:AssumeRole. That is the single, narrow, revocable permission hh.com's
# policy needs -- not a standing acm:*/route53:* allowance.
#
# Creating or changing this role is itself IAM administration. Apply it with
# Heinrich's own privileged AWS identity, never with hh.com's credentials --
# an automation user must never be able to create or alter IAM roles,
# including this one. See README.md, "Manual steps only Heinrich can do".
# =============================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "dev_infra_automation" {
  name        = "eg-levern-dev-infra-automation"
  description = <<-EOT
    Assumed by hh.com to request the dev.eg-levern.de certificate and manage
    its DNS records. Created and changed only by Heinrich's own AWS
    identity -- never by hh.com.
  EOT

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/hh.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "dev_infra_automation" {
  name = "dev-certificate-and-dns"
  role = aws_iam_role.dev_infra_automation.id

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
        # Scoped to the one zone once its ID is known; falls back to every
        # zone in the account only because nobody with Route 53 read access
        # has looked the ID up yet. Fill in eg_levern_hosted_zone_id first.
        Resource = (
          var.eg_levern_hosted_zone_id != ""
          ? "arn:aws:route53:::hostedzone/${var.eg_levern_hosted_zone_id}"
          : "arn:aws:route53:::hostedzone/*"
        )
      },
    ]
  })
}

output "dev_infra_automation_role_arn" {
  description = <<-EOT
    ARN hh.com's own policy needs sts:AssumeRole on -- the only permission
    hh.com gains from this ticket. Grant it with Heinrich's own AWS
    identity, same as applying this file.
  EOT
  value       = aws_iam_role.dev_infra_automation.arn
}

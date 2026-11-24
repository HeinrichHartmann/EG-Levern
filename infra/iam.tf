# =============================================================================
# IAM -- a dedicated user for this premise (EG-Levern), scoped to exactly
# what OpenTofu needs for the dev certificate and its DNS records.
#
# hh.com is already denied acm:RequestCertificate and all route53:* (see
# README.md), and stays that way: hh.com runs unattended deploys, and a
# principal that can request certificates and change DNS for eg-levern.de
# is one step away from a principal that could escalate to full account
# control, if it or anything using its credentials ever also held
# iam:CreateRole / iam:PutRolePolicy. Widening hh.com's policy, or routing
# through hh.com via sts:AssumeRole, both mean sharing this capability with
# whatever already holds hh.com's credentials (unattended deploys, any
# agent that runs them). Instead this premise gets its own standing
# identity, used for nothing else, so the permission below never has to be
# shared with a broader-purpose principal.
#
# Creating or changing this user is itself IAM administration. Apply it
# with Heinrich's own privileged AWS identity, never with hh.com's
# credentials -- an automation user must never be able to create or alter
# IAM users/policies, including this one. See README.md, "Manual steps
# only Heinrich can do".
# =============================================================================

resource "aws_iam_user" "dev_infra_automation" {
  name = "eg-levern-dev-infra-automation"

  tags = {
    Premise = "eg-levern"
  }
}

# The secret access key below lands in this user's state file
# (s3://eg-levern-tofu-state), which is private and encrypted but still
# plaintext within the state itself, including in older object versions
# after a rotation. If that's unacceptable, drop this resource and the two
# access-key outputs, and create the access key by hand in the console
# instead -- aws_iam_user and aws_iam_user_policy above are unaffected.
resource "aws_iam_access_key" "dev_infra_automation" {
  user = aws_iam_user.dev_infra_automation.name
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

output "dev_infra_automation_access_key_id" {
  description = "Access key ID for the dedicated eg-levern-dev-infra-automation user."
  value       = aws_iam_access_key.dev_infra_automation.id
}

output "dev_infra_automation_secret_access_key" {
  description = <<-EOT
    Secret access key for the dedicated eg-levern-dev-infra-automation
    user. Retrieve with `tofu output -raw dev_infra_automation_secret_access_key`
    and store it directly in ~/box/secrets/ -- never print it to a
    terminal you're sharing or paste it into chat.
  EOT
  value       = aws_iam_access_key.dev_infra_automation.secret
  sensitive   = true
}

# Production -- consumed by `make deploy` / `make diff`
output "prod_bucket" {
  description = "S3 sync target for the production site."
  value       = aws_s3_bucket.prod.bucket
}

output "prod_distribution_id" {
  description = "CloudFront distribution invalidated by `make deploy`."
  value       = aws_cloudfront_distribution.prod.id
}

output "prod_url" {
  description = "Public production URL."
  value       = "https://${var.domain}/"
}

# Dev -- consumed by `make deploy-dev` / `make diff-dev`
output "dev_bucket" {
  description = "S3 sync target for the dev site."
  value       = aws_s3_bucket.dev.bucket
}

output "dev_distribution_id" {
  description = "CloudFront distribution invalidated by `make deploy-dev`."
  value       = aws_cloudfront_distribution.dev.id
}

output "dev_url" {
  description = <<-EOT
    Where to review the dev site. Falls back to the *.cloudfront.net domain
    until a certificate exists and dev_custom_domain_enabled is turned on.
  EOT
  value       = local.dev_alias_enabled ? "https://${var.dev_domain}/" : "https://${aws_cloudfront_distribution.dev.domain_name}/"
}

output "dev_cloudfront_domain" {
  description = "Always-available dev domain, independent of DNS."
  value       = aws_cloudfront_distribution.dev.domain_name
}

# -----------------------------------------------------------------------------
# Manual DNS handover -- see infra/README.md
#
# The deploy IAM user has no Route 53 access, so these records have to be
# created by hand. Printing them here means nobody has to dig them out of
# the ACM console.
# -----------------------------------------------------------------------------

output "dev_dns_records_for_heinrich" {
  description = "Records Heinrich must create in the eg-levern.de hosted zone."
  value = {
    # Empty while `dev_manage_certificate` is false -- the deploy user
    # cannot request the certificate, so there is no validation record to
    # report yet. The ACM console shows it when the cert is made by hand.
    acm_validation = flatten([
      for cert in aws_acm_certificate.dev[*] : [
        for o in cert.domain_validation_options : {
          name  = o.resource_record_name
          type  = o.resource_record_type
          value = o.resource_record_value
        }
      ]
    ])
    alias = {
      name                   = "${var.dev_domain}."
      type                   = "A (Alias)"
      target                 = aws_cloudfront_distribution.dev.domain_name
      target_hosted_zone_id  = aws_cloudfront_distribution.dev.hosted_zone_id
      evaluate_target_health = false
    }
  }
}

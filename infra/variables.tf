variable "aws_region" {
  description = "Region for the S3 origin buckets."
  type        = string
  default     = "eu-central-1"
}

variable "domain" {
  description = "Apex domain of the production site."
  type        = string
  default     = "eg-levern.de"
}

variable "dev_domain" {
  description = "Domain the dev environment will eventually serve on."
  type        = string
  default     = "dev.eg-levern.de"
}

variable "prod_certificate_arn" {
  description = <<-EOT
    ARN of the existing, already-validated production certificate.
    Referenced as a data source; this configuration never creates or
    replaces the production certificate.
  EOT
  type        = string
  default     = "arn:aws:acm:us-east-1:710931427457:certificate/cc91ec3c-d9b0-4994-879b-9e7a5b38a97a"
}

variable "dev_manage_certificate" {
  description = <<-EOT
    Let this configuration request the dev.eg-levern.de certificate.

    Default false because the deploy IAM user is denied
    acm:RequestCertificate. Set to true once Heinrich grants that
    permission; OpenTofu will then create the certificate and print its
    DNS validation record in the `dev_dns_records_for_heinrich` output.

    Mutually exclusive with `dev_certificate_arn`.
  EOT
  type        = bool
  default     = false
}

variable "dev_certificate_arn" {
  description = <<-EOT
    ARN of a dev.eg-levern.de certificate created outside this
    configuration (us-east-1), for when Heinrich requests it by hand in
    the ACM console instead of granting acm:RequestCertificate.

    Ignored when `dev_manage_certificate` is true.
  EOT
  type        = string
  default     = ""
}

variable "dev_custom_domain_enabled" {
  description = <<-EOT
    Attach `dev_domain` and its certificate to the dev distribution.

    Keep this false until the certificate reports ISSUED. CloudFront
    rejects an alias whose certificate is still PENDING_VALIDATION, and
    validation needs a DNS record only Heinrich can create (the deploy
    IAM user has no Route 53 access -- see infra/README.md).

    Has no effect unless a certificate is available via
    `dev_manage_certificate` or `dev_certificate_arn`. While the alias is
    off, the dev site is served over its *.cloudfront.net domain.
  EOT
  type        = bool
  default     = false
}

variable "eg_levern_hosted_zone_id" {
  description = <<-EOT
    Route 53 hosted zone ID for eg-levern.de, used in iam.tf to scope the
    dev_infra_automation role's DNS permissions to that one zone. Find it
    under Route 53 -> Hosted zones in the console.

    Left empty (the role then falls back to every zone in the account)
    only because nobody with Route 53 read access has looked it up yet --
    fill it in as soon as you have it.
  EOT
  type        = string
  default     = ""
}

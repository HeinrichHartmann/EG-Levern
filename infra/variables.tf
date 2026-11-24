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

    Stays false: the certificate already exists, created out of band with
    the dev_infra_automation user's credentials (see SIG-10), and is
    referenced by ARN via `dev_certificate_arn` instead. Flipping this to
    true would request a *second*, redundant certificate.

    Mutually exclusive with `dev_certificate_arn`.
  EOT
  type        = bool
  default     = false
}

variable "dev_certificate_arn" {
  description = <<-EOT
    ARN of the dev.eg-levern.de certificate. Created outside this
    configuration (us-east-1, DNS-validated) and ISSUED, so it is
    referenced rather than managed -- the same arrangement as
    `prod_certificate_arn`.

    Ignored when `dev_manage_certificate` is true.
  EOT
  type        = string
  default     = "arn:aws:acm:us-east-1:710931427457:certificate/bfa0102d-8a60-4ba9-b346-27b97603b252"
}

variable "dev_custom_domain_enabled" {
  description = <<-EOT
    Attach `dev_domain` and its certificate to the dev distribution.

    On: the certificate reports ISSUED and the dev.eg-levern.de alias
    A-record already points at the dev distribution, so CloudFront
    accepts the alias.

    Set it back to false to park the dev environment on its
    *.cloudfront.net domain again; that is a safe, reversible change (the
    DNS record simply stops resolving to a distribution that claims it).
  EOT
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "IAM is global; this only sets the provider's endpoint region."
  type        = string
  default     = "eu-central-1"
}

variable "eg_levern_hosted_zone_id" {
  description = <<-EOT
    Route 53 hosted zone ID for eg-levern.de, used to scope the
    dev_infra_automation user's DNS permissions to that one zone.
  EOT
  type        = string
  default     = "Z04680512670ECR8ZN9DQ"
}

# -----------------------------------------------------------------------------
# Deploy scope -- which buckets/distributions dev_infra_automation may
# write to and invalidate. Pinned values, not looked up from ../, so this
# module's plan never needs read access to the other module's state.
# -----------------------------------------------------------------------------

variable "aws_account_id" {
  description = "Account id, used to build the CloudFront distribution ARNs below."
  type        = string
  default     = "710931427457"
}

variable "prod_bucket_name" {
  description = "Production site bucket dev_infra_automation may deploy to."
  type        = string
  default     = "eg-levern.de"
}

variable "dev_bucket_name" {
  description = "Dev site bucket dev_infra_automation may deploy to."
  type        = string
  default     = "dev.eg-levern.de"
}

variable "prod_distribution_id" {
  description = "Production CloudFront distribution id, for cache invalidation."
  type        = string
  default     = "E1RRMW11A78TZM"
}

variable "dev_distribution_id" {
  description = "Dev CloudFront distribution id, for cache invalidation."
  type        = string
  default     = "E1SL20ASNAYEAH"
}

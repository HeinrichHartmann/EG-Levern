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

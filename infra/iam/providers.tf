terraform {
  required_version = "~> 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }

  # A *separate* state file from the site configuration in ../, on purpose.
  #
  # Terraform/OpenTofu refreshes every resource in a state file on every
  # plan, so any principal that plans this configuration needs read access
  # to everything in it. With the IAM user in the same state as the buckets
  # and distributions, `tofu plan` failed outright for the deploy user:
  #
  #   Error: reading IAM User (eg-levern-dev-infra-automation): api error
  #   AccessDenied: User: arn:aws:iam::710931427457:user/hh.com is not
  #   authorized to perform: iam:GetUser
  #
  # Splitting the state keeps the two privilege tiers independent: ../ is
  # planned and applied routinely with the deploy credentials, this one is
  # touched rarely and only with Heinrich's own privileged identity.
  backend "s3" {
    bucket  = "eg-levern-tofu-state"
    key     = "eg-levern.de/iam.tfstate"
    region  = "eu-central-1"
    encrypt = true

    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

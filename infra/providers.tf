terraform {
  # >= 1.10 is required for the S3 backend's native `use_lockfile` locking.
  required_version = "~> 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }

  # State lives in a dedicated private bucket in the same account.
  # This repo is public, so state must never be committed here.
  #
  # The bucket was created out-of-band (versioned, AES256-encrypted, all
  # public access blocked) because a backend cannot bootstrap its own
  # storage. It is deliberately NOT managed by this configuration.
  backend "s3" {
    bucket  = "eg-levern-tofu-state"
    key     = "eg-levern.de/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true

    # Native S3 locking -- no DynamoDB table required.
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront viewer certificates must live in us-east-1, regardless of
# where the origin bucket is.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

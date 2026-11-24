# =============================================================================
# PRODUCTION -- eg-levern.de
#
# Every resource here already existed (hand-built in the console, 2021) and
# was adopted via the `import` blocks below. The configuration is written to
# match the live state byte-for-byte, so `tofu plan` reports no changes.
#
# Do not "clean up" anything in this file casually: a change that forces
# replacement of the distribution takes the cooperative's website offline.
# =============================================================================

locals {
  prod_aliases = [var.domain, "www.${var.domain}"]

  # S3 *website* endpoint, not the REST endpoint. This predates OAC, so the
  # bucket is public-read and CloudFront talks to it as a custom origin.
  # Migrating to OAC is a prod-affecting change and deliberately out of scope.
  prod_origin_id = aws_s3_bucket_website_configuration.prod.website_endpoint
}

# -----------------------------------------------------------------------------
# Imports -- adopt the existing infrastructure instead of recreating it
# -----------------------------------------------------------------------------

import {
  to = aws_s3_bucket.prod
  id = "eg-levern.de"
}

import {
  to = aws_s3_bucket_website_configuration.prod
  id = "eg-levern.de"
}

import {
  to = aws_s3_bucket_public_access_block.prod
  id = "eg-levern.de"
}

import {
  to = aws_s3_bucket_policy.prod
  id = "eg-levern.de"
}

import {
  to = aws_cloudfront_distribution.prod
  id = "E1RRMW11A78TZM"
}

# -----------------------------------------------------------------------------
# Origin bucket -- `make deploy` syncs ./public here
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "prod" {
  bucket = var.domain
}

resource "aws_s3_bucket_website_configuration" "prod" {
  bucket = aws_s3_bucket.prod.id

  index_document {
    suffix = "index.html"
  }
}

# The site is served through the public S3 website endpoint, so the
# account-level public-access guards are all off for this bucket.
resource "aws_s3_bucket_public_access_block" "prod" {
  bucket = aws_s3_bucket.prod.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "prod" {
  bucket = aws_s3_bucket.prod.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.prod.arn}/*"
    }]
  })

  # A bucket policy cannot be accepted while the public-access block still
  # rejects public policies.
  depends_on = [aws_s3_bucket_public_access_block.prod]
}

# -----------------------------------------------------------------------------
# TLS -- existing certificate, referenced only, never created
# -----------------------------------------------------------------------------

# The production certificate is referenced by its pinned ARN
# (`var.prod_certificate_arn`), never created or replaced here.
#
# A `data "aws_acm_certificate"` lookup would be the tidier way to express
# this, but the AWS provider's ACM data source calls acm:GetCertificate,
# and the deploy user is denied that action:
#
#   AccessDeniedException: User: arn:aws:iam::710931427457:user/hh.com is
#   not authorized to perform: acm:GetCertificate
#
# (acm:ListCertificates and acm:DescribeCertificate *are* allowed, so the
# certificate can still be inspected with the CLI. If Heinrich ever adds
# acm:GetCertificate, this can become a data source.)
#
# Verified by hand, 2026-11-24:
#   arn:...:certificate/cc91ec3c-d9b0-4994-879b-9e7a5b38a97a
#   domain eg-levern.de, SANs [eg-levern.de, www.eg-levern.de], ISSUED

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "prod" {
  enabled         = true
  aliases         = local.prod_aliases
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = "PriceClass_100"

  # Intentionally empty: the S3 website endpoint resolves index documents
  # for sub-paths itself, which a CloudFront default root object does not.
  default_root_object = ""

  origin {
    domain_name = local.prod_origin_id
    origin_id   = local.prod_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      # Matches the live distribution. S3 website endpoints are HTTP-only,
      # so this list is never actually exercised.
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.prod_origin_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Managed-CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.prod_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# =============================================================================
# DNS -- not managed here
#
# eg-levern.de is delegated to Route 53, but the deploy IAM user `hh.com` is
# denied route53:ListHostedZones, so the zone cannot be read or imported.
# The live records (apex + www A/ALIAS to the distribution, plus the ACM
# validation CNAMEs) stay manual. See infra/README.md.
# =============================================================================

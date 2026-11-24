# =============================================================================
# DEV -- dev.eg-levern.de
#
# A review environment that mirrors production closely enough to be a real
# test of the built site (CloudFront + HTTPS + the S3 website endpoint's
# index-document behaviour), but is kept out of search engines.
#
# Created by this configuration, not imported.
# =============================================================================

locals {
  dev_origin_id = aws_s3_bucket_website_configuration.dev.website_endpoint

  # Either the certificate this configuration manages, or one created out of
  # band by Heinrich. Empty means "no custom domain yet".
  dev_certificate_arn = (
    var.dev_manage_certificate
    ? one(aws_acm_certificate.dev[*].arn)
    : var.dev_certificate_arn
  )

  # An alias may only be attached once there is a validated certificate to
  # serve it with; CloudFront rejects the alias otherwise.
  dev_alias_enabled = var.dev_custom_domain_enabled && local.dev_certificate_arn != ""
}

# -----------------------------------------------------------------------------
# Origin bucket -- `make deploy-dev` syncs ./public here
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "dev" {
  bucket = var.dev_domain
}

resource "aws_s3_bucket_website_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = aws_s3_bucket.dev.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dev" {
  bucket = aws_s3_bucket.dev.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.dev.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.dev]
}

# -----------------------------------------------------------------------------
# Keep dev out of search engines
#
# The content is a real cooperative's, so an indexed duplicate would both
# hurt the production site's SEO and risk members reading stale prices.
# Belt and braces: this header, plus the `robots.txt` that `make deploy-dev`
# uploads (prod has no robots.txt and is left untouched).
# -----------------------------------------------------------------------------

resource "aws_cloudfront_response_headers_policy" "dev_noindex" {
  name    = "eg-levern-dev-noindex"
  comment = "Adds X-Robots-Tag: noindex to the dev.eg-levern.de distribution"

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow"
      override = true
    }
  }
}

# -----------------------------------------------------------------------------
# TLS
#
# The dev certificate already exists and is ISSUED. It was requested out of
# band with the dev_infra_automation user's credentials, so this
# configuration references it by ARN (var.dev_certificate_arn) rather than
# managing it -- the same arrangement as the production certificate, and the
# reason dev_manage_certificate stays false. Setting it to true would request
# a second, redundant certificate for the same name.
#
# The resource below is kept only so the certificate *can* be brought under
# management later (or recreated from scratch in another account) without
# rewriting dev.tf.
#
# There is deliberately no aws_acm_certificate_validation resource: it would
# block `tofu apply` for up to an hour waiting on DNS.
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "dev" {
  count    = var.dev_manage_certificate ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.dev_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# CloudFront
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "dev" {
  enabled         = true
  aliases         = local.dev_alias_enabled ? [var.dev_domain] : []
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = "PriceClass_100"
  comment         = "dev.eg-levern.de -- review environment, noindex"

  default_root_object = ""

  origin {
    domain_name = local.dev_origin_id
    origin_id   = local.dev_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.dev_origin_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Managed-CachingDisabled: a review environment should show the content
    # that was just deployed, without waiting on an invalidation.
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.dev_noindex.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Without a validated certificate there is no alias to serve, so fall
    # back to the default *.cloudfront.net certificate.
    cloudfront_default_certificate = local.dev_alias_enabled ? null : true

    acm_certificate_arn      = local.dev_alias_enabled ? local.dev_certificate_arn : null
    ssl_support_method       = local.dev_alias_enabled ? "sni-only" : null
    minimum_protocol_version = local.dev_alias_enabled ? "TLSv1.2_2021" : null
  }
}

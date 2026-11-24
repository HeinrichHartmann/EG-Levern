# Infrastructure

OpenTofu configuration for the two eg-levern.de hosting environments.

Both are the same shape: a public-read S3 bucket with *website* hosting
enabled, fronted by CloudFront. The site itself is built by Hugo and pushed
with `make deploy` / `make deploy-dev` from the repository root — OpenTofu
manages the hosting, never the page content.

| | Production | Dev / review |
|---|---|---|
| Bucket | `eg-levern.de` | `dev.eg-levern.de` |
| Distribution | `E1RRMW11A78TZM` | `E1SL20ASNAYEAH` |
| URL | <https://eg-levern.de/> | <https://d2thkgludxk7z8.cloudfront.net/> |
| Custom domain | yes (`eg-levern.de`, `www.`) | **not yet** — needs DNS, see below |
| Cache policy | Managed-CachingOptimized | Managed-CachingDisabled |
| Indexable | yes | no (`X-Robots-Tag` + `robots.txt`) |

## Layout

| File | Contents |
|---|---|
| `providers.tf` | Version pins, S3 state backend, the two AWS providers |
| `prod.tf` | Production, **all imported** from the pre-existing console setup |
| `dev.tf` | Dev environment, created by this configuration |
| `iam.tf` | The `dev_infra_automation` role hh.com assumes for ACM/Route 53 |
| `variables.tf` | Inputs, including the dev certificate/DNS switches |
| `outputs.tf` | Bucket + distribution ids, and the DNS handover values |
| `dev-robots.txt` | Uploaded to the dev bucket only, by `make deploy-dev` |

Flat on purpose: there is no second site to share modules with yet.

## Running it

`tofu` comes from the repo's Nix dev shell:

```sh
nix develop          # or: direnv allow
cd infra
tofu init
tofu plan
```

`make infra-plan` / `make infra-apply` from the repo root do the same thing.

AWS credentials come from `~/box/secrets/aws-credentials-hhcom` via
`AWS_SHARED_CREDENTIALS_FILE`, exported by the root `Makefile`. When running
`tofu` directly, export it yourself:

```sh
export AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-hhcom
```

### State

Remote, in a dedicated private bucket in the same account:

```
s3://eg-levern-tofu-state/eg-levern.de/terraform.tfstate
```

Versioned, AES256-encrypted, all public access blocked. Locking uses the S3
backend's native `use_lockfile` (no DynamoDB table), which is why
`required_version` is `~> 1.13`.

That bucket is **not** managed by this configuration — a backend cannot
bootstrap the storage it lives in. It was created by hand:

```sh
aws s3api create-bucket --bucket eg-levern-tofu-state --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-public-access-block --bucket eg-levern-tofu-state \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-versioning --bucket eg-levern-tofu-state \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket eg-levern-tofu-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

State must never be committed: this repository is public.

## Imported vs. managed

**Imported** (built by hand in the AWS console in 2021, adopted via `import`
blocks in `prod.tf`; the configuration was written to match the live state so
the plan comes out empty):

- `aws_s3_bucket.prod`
- `aws_s3_bucket_website_configuration.prod`
- `aws_s3_bucket_public_access_block.prod`
- `aws_s3_bucket_policy.prod`
- `aws_cloudfront_distribution.prod`

**Managed** (created by this configuration): everything in `dev.tf`.

**Referenced, never created:** the production ACM certificate
(`cc91ec3c-…`), pinned as `var.prod_certificate_arn`.

**Not represented at all:** DNS (see below), and the production certificate's
validation records.

> The production distribution must never be replaced — that takes the
> cooperative's website offline. Treat any plan that proposes replacing
> `aws_cloudfront_distribution.prod` as a bug in the configuration, not as
> something to approve.

### Why prod uses the S3 *website* endpoint

The origin is `eg-levern.de.s3-website.eu-central-1.amazonaws.com`, not the
REST endpoint, so the bucket has to be public-read and cannot use Origin
Access Control. It also means `default_root_object` is deliberately empty:
the website endpoint resolves `index.html` for *every* sub-path, which a
CloudFront default root object does not.

Moving to an OAC/REST origin would be a genuine improvement but is a
production-affecting change; it is out of scope here and deserves its own
ticket. Dev mirrors the current prod arrangement so that it stays a faithful
test of it.

### Keeping dev out of search engines

The dev site is a copy of a real cooperative's content, including tariffs.
An indexed duplicate would hurt the production site's ranking and could
show members prices that are not in force. Two independent mechanisms:

1. `aws_cloudfront_response_headers_policy.dev_noindex` adds
   `X-Robots-Tag: noindex, nofollow` to every dev response.
2. `make deploy-dev` uploads `dev-robots.txt` as `/robots.txt` *after* the
   site sync, so it always wins. Production has no `robots.txt` and is left
   untouched.

Verify both:

```sh
curl -sI https://d2thkgludxk7z8.cloudfront.net/ | grep -i x-robots-tag
curl -s  https://d2thkgludxk7z8.cloudfront.net/robots.txt
```

## Manual steps only Heinrich can do

The deploy IAM user `hh.com` is missing three permissions. Nothing below can
be automated until they are granted; none of it blocks using the dev
environment on its CloudFront domain today.

None of these should ever be granted to `hh.com` directly, including by
hand in the console. `hh.com` runs unattended deploys; a principal that can
request certificates and change DNS is one `iam:CreateRole` away from full
account takeover, and this is exactly the kind of standing permission that
turns a compromised deploy credential into a compromised account. `iam.tf`
instead defines `dev_infra_automation`, a role scoped to just the ACM/Route
53 actions below, which `hh.com` may reach only via `sts:AssumeRole`. The
one new permission `hh.com`'s own policy needs is that single
`sts:AssumeRole` grant on that one role ARN — never the underlying
`acm:*`/`route53:*` actions themselves.

Applying `iam.tf` and granting that `sts:AssumeRole` permission are both IAM
administration. Both require Heinrich's own privileged AWS identity — never
`hh.com`'s credentials, and not anything an agent holds, since none of this
repo's automation has (or should have) standing AWS access.

### 1. DNS — `route53:*` is denied

```
AccessDenied: User: arn:aws:iam::710931427457:user/hh.com is not authorized
to perform: route53:ListHostedZones
```

So the hosted zone cannot even be read, let alone imported. All DNS for
eg-levern.de — the apex and `www` A/ALIAS records, and the production
certificate's validation CNAMEs — stays manual and is not represented in
this configuration.

### 2. `acm:RequestCertificate` is denied

So `dev.eg-levern.de` has no certificate, which is why the dev distribution
currently serves its `*.cloudfront.net` domain with the default CloudFront
certificate and has no alias attached.

### 3. `acm:GetCertificate` is denied

Minor: it is the only reason `prod.tf` pins the production certificate ARN in
a variable instead of using a `data "aws_acm_certificate"` lookup.
`acm:ListCertificates` and `acm:DescribeCertificate` *are* allowed.

### Giving dev a real `https://dev.eg-levern.de` URL

Pick one of the two routes, then do step 3 and 4 either way.

**Route A — apply the automation role and let OpenTofu do it (preferred).**
With your own privileged AWS identity:

```sh
cd infra
tofu apply -target=aws_iam_role.dev_infra_automation -target=aws_iam_role_policy.dev_infra_automation
tofu output dev_infra_automation_role_arn
```

Then grant `hh.com`'s own policy `sts:AssumeRole` on that one ARN (nothing
else — see "Manual steps only Heinrich can do" above for why), and point
OpenTofu's AWS provider at it (e.g. an `assume_role` block, or an AWS CLI
profile with `role_arn` + `source_profile` in `~/.aws/config`). From then
on:

```sh
tofu apply -var dev_manage_certificate=true
tofu output dev_dns_records_for_heinrich   # prints the validation record
```

**Route B — create the certificate by hand.** In the ACM console, **region
us-east-1** (CloudFront only accepts certificates from us-east-1), request a
public certificate for `dev.eg-levern.de` with **DNS validation**. ACM shows
one CNAME record to create. Then record the ARN:

```sh
tofu apply -var dev_certificate_arn=arn:aws:acm:us-east-1:710931427457:certificate/XXXX
```

**Step 3 — create two records** in the `eg-levern.de` hosted zone:

| Purpose | Name | Type | Value |
|---|---|---|---|
| Certificate validation | `_xxxx.dev.eg-levern.de.` | `CNAME` | `_yyyy.acm-validations.aws.` (exact values from the output/console above) |
| Site alias | `dev.eg-levern.de.` | `A` — Alias | Alias to CloudFront `d2thkgludxk7z8.cloudfront.net` (hosted zone `Z2FDTNDATAQYW2`, evaluate target health: no) |

The alias record can be created immediately; it does not depend on the
certificate. Until it exists, `https://dev.eg-levern.de/` will not resolve.

**Step 4 — attach the alias** once ACM reports the certificate `ISSUED`
(usually a few minutes after the validation record propagates):

```sh
aws acm describe-certificate --region us-east-1 \
  --certificate-arn <arn> --query 'Certificate.Status'

tofu apply -var dev_custom_domain_enabled=true   # plus the var from A or B
```

CloudFront rejects an alias whose certificate is not yet `ISSUED`, which is
why this is a separate, explicit switch. To make any of these settings
permanent rather than passing `-var` each time, put them in
`infra/terraform.tfvars` (gitignored).

## Deploying the site

From the repository root — **not** from here:

```sh
make deploy-dev   # -> dev.eg-levern.de bucket  + dev distribution
make deploy       # -> PRODUCTION. Real customers. Ask first.
```

While `dev.eg-levern.de` has no DNS, build dev against the CloudFront domain
so any absolute URLs resolve:

```sh
make deploy-dev DEV_BASEURL=https://d2thkgludxk7z8.cloudfront.net/
```

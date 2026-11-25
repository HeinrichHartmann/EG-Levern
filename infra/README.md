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
| URL | <https://eg-levern.de/> | <https://dev.eg-levern.de/> |
| CloudFront domain | `d6cay05t1kw8j.cloudfront.net` | `d2thkgludxk7z8.cloudfront.net` |
| Custom domain | yes (`eg-levern.de`, `www.`) | yes (`dev.eg-levern.de`) |
| Cache policy | Managed-CachingOptimized | Managed-CachingDisabled |
| Indexable | yes | no (`X-Robots-Tag` + `robots.txt`) |

## Layout

Two **separate root modules**, each with its own state file:

### `infra/` — the hosting, applied with the deploy credentials

| File | Contents |
|---|---|
| `providers.tf` | Version pins, S3 state backend, the two AWS providers |
| `prod.tf` | Production, **all imported** from the pre-existing console setup |
| `dev.tf` | Dev environment, created by this configuration |
| `variables.tf` | Inputs, including the dev certificate/domain switches |
| `outputs.tf` | Bucket + distribution ids, and the expected DNS values |
| `dev-robots.txt` | Uploaded to the dev bucket only, by `make deploy-dev` |

Flat on purpose: there is no second site to share modules with yet.

### `infra/iam/` — the automation identity, applied by Heinrich only

| File | Contents |
|---|---|
| `iam.tf` | The dedicated `eg-levern-dev-infra-automation` user and its policy |
| `providers.tf` | Its own state key, `eg-levern.de/iam.tfstate` |
| `variables.tf` | The `eg-levern.de` hosted zone id the policy is scoped to |

**Why this is split off rather than one more file in `infra/`.** OpenTofu
refreshes every resource in a state file on every plan, so whoever plans a
configuration needs read access to everything in it. With the IAM user in
the same state as the buckets, `tofu plan` failed outright for the deploy
user — not just for the IAM resources, for the whole run:

```
Error: reading IAM User (eg-levern-dev-infra-automation): api error
AccessDenied: User: arn:aws:iam::710931427457:user/hh.com is not
authorized to perform: iam:GetUser
```

which also broke `make infra-plan` and `make infra-apply`. The alternative
— granting `hh.com` IAM read — would have put the deploy credential one
policy edit away from reading the account's IAM layout, to work around a
problem that separate state solves outright. Two states, two privilege
tiers, no extra permissions.

### The access key is not in OpenTofu

`infra/iam/iam.tf` manages the user and its policy, but **not** its access
key. An `aws_iam_access_key` resource stores the secret in plaintext in
state — including in older object versions after any rotation — and AWS
never returns a secret again after creation, so the resource also cannot be
re-imported if state is ever rebuilt. The key is created by hand in the IAM
console and saved to `~/box/secrets/aws-credentials-eg-levern`.

This repo is public, so the key ID is not written down here — it goes stale
on every rotation anyway. To see which key is in use:

```sh
AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-eg-levern \
  aws sts get-access-key-info --access-key-id "$(
    AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-eg-levern \
      aws configure get aws_access_key_id)"
```

To rotate: create a second key in the console, update that file, verify with
`aws sts get-caller-identity`, then delete the old key. No OpenTofu involved.

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

Remote, in a dedicated private bucket in the same account, one key per root
module:

```
s3://eg-levern-tofu-state/eg-levern.de/terraform.tfstate   # infra/
s3://eg-levern-tofu-state/eg-levern.de/iam.tfstate         # infra/iam/
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

**Managed** (created by this configuration): everything in `dev.tf`, except
the certificate. `infra/iam/` manages the automation user and its policy.

**Referenced, never created:** both ACM certificates, pinned as
`var.prod_certificate_arn` (`cc91ec3c-…`) and `var.dev_certificate_arn`
(`bfa0102d-…`). Both are DNS-validated and `ISSUED`; neither is managed
here, so no plan can ever replace a certificate the live sites depend on.

**Not represented at all:**

- **DNS.** The `eg-levern.de` zone is `Z04680512670ECR8ZN9DQ`. The deploy
  user has no Route 53 access at all; the `dev_infra_automation` user has
  read/write scoped to that one zone. Records are managed by hand — the
  apex and `www` A/ALIAS records, `dev.eg-levern.de`, and both
  certificates' validation CNAMEs. `output dev_dns_records_for_heinrich`
  prints what the dev records should look like.
- **The state bucket** (`eg-levern-tofu-state`) — a backend cannot
  bootstrap its own storage.
- **The automation user's access key** — see above.

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
curl -sI https://dev.eg-levern.de/ | grep -i x-robots-tag
curl -s  https://dev.eg-levern.de/robots.txt
```

Expected: `x-robots-tag: noindex, nofollow`, and a `robots.txt` whose body
ends in `Disallow: /`. Production must keep returning 404 for
`/robots.txt` — if it ever does not, something has deployed the dev
`robots.txt` to prod:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://eg-levern.de/robots.txt   # 404
```

## Permissions and who can do what

Three AWS identities are involved. The split exists so that no single
credential used for routine, unattended work can touch IAM — a compromised
deploy or automation credential should not be able to escalate to account
control.

| Identity | Credentials | Can do | Used for |
|---|---|---|---|
| `hh.com` | `~/box/secrets/aws-credentials-hhcom` | S3, CloudFront, ACM read | `infra/` plan+apply only |
| `eg-levern-dev-infra-automation` | `~/box/secrets/aws-credentials-eg-levern` | dev ACM certs (us-east-1), Route 53 on the `eg-levern.de` zone, S3 + CloudFront invalidation on the two site buckets/distributions | `make deploy`, `make deploy-dev`, `make diff`, `make diff-dev`, certificate and DNS changes |
| Heinrich's own admin identity | Bitwarden, via `scripts/with-bw-admin.sh` | everything | `infra/iam/` plan+apply only |

**Deploy identity changed on SIG-9, 2026-11-25.** `make deploy` /
`make deploy-dev` used to run as `hh.com`; they now run as
`eg-levern-dev-infra-automation` (Heinrich's explicit choice over widening
`hh.com` or standing up a fourth identity — see `iam.tf`'s header comment
for the accepted tradeoff). `hh.com` keeps S3/CloudFront/ACM-read only for
`infra/` plan+apply, which needs broader bucket- and distribution-admin
permissions the automation user does not have.

`hh.com` is deliberately denied `acm:RequestCertificate`, all `route53:*`,
and all `iam:*`. Do not widen it for those — use the automation user
instead. It does have `acm:ListCertificates` and `acm:DescribeCertificate`,
which is enough to check certificate status.

> **This policy widening does not take effect until applied.** The S3 +
> CloudFront statements above are defined in `infra/iam/iam.tf`, but that
> module only applies with Heinrich's own identity (see below). Until
> `make infra-iam-apply` has been run with this change in it, the
> automation user's *actual* AWS policy still lacks S3/CloudFront, and
> `make deploy` / `make deploy-dev` / `make diff` / `make diff-dev` will
> fail with `AccessDenied`. No new access key is needed — the existing one
> in `~/box/secrets/aws-credentials-eg-levern` keeps working once the
> policy is applied.

### Applying `infra/iam/`

Needed only when the automation user's policy changes. Requires Heinrich's
own identity, fetched from Bitwarden by `infra/scripts/with-bw-admin.sh`
rather than a credentials file on disk:

```sh
cd infra/iam && ../scripts/with-bw-admin.sh tofu init   # first run only
make infra-iam-plan
make infra-iam-apply
```

(`make infra-plan` / `make infra-apply`, by contrast, use `hh.com` and
never touch this module.)

> **The user and its policy already exist in AWS but are not yet in this
> module's state** — they were created before the state split. `iam.tf`
> carries `import` blocks for both, so the three commands above adopt them
> automatically; there is nothing extra to run and no import ID to retype.
>
> Importing needs `iam:GetUser`, which neither `hh.com` nor the automation
> user itself has (both get `AccessDenied`), so the import only resolves on
> your first run with your own identity. Until then `tofu plan` in this
> module fails at the import — that is expected and affects nothing else.
>
> Once imported, the plan should show one in-place change: the
> `EgLevernZoneRecords` statement narrows from
> `arn:aws:route53:::hostedzone/*` to the single
> `Z04680512670ECR8ZN9DQ` zone. That tightening is the only pending IAM
> change; nothing depends on it, the automation user works either way.

Nothing else is blocked on this. `infra/` plans and applies cleanly without
it.

### DNS — manual, by design

`route53:*` is denied for `hh.com`, so DNS is not in IaC. The
`eg-levern.de` hosted zone is `Z04680512670ECR8ZN9DQ`. Current dev records,
both already in place:

| Purpose | Name | Type | Value |
|---|---|---|---|
| Site alias | `dev.eg-levern.de.` | `A` — Alias | CloudFront `d2thkgludxk7z8.cloudfront.net`, hosted zone `Z2FDTNDATAQYW2`, evaluate target health: no |
| Certificate validation | `_e8fb965c1e84b99562a6bf57d3a15763.dev.eg-levern.de.` | `CNAME` | `_e055d8f033054705598b84f4728c15f6.wzccmgtwzk.acm-validations.aws.` |

The validation CNAME must stay: ACM re-checks it to keep the certificate
renewing automatically. Deleting it would eventually break TLS on
`dev.eg-levern.de`.

Inspect the zone with the automation user:

```sh
export AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-eg-levern
aws route53 list-resource-record-sets --hosted-zone-id Z04680512670ECR8ZN9DQ
```

### Turning the dev custom domain off again

`dev_custom_domain_enabled` detaches the alias and falls back to the
CloudFront domain. Reversible, dev-only:

```sh
cd infra && tofu apply -var dev_custom_domain_enabled=false
```

To make any `-var` setting permanent, put it in `infra/terraform.tfvars`
(gitignored).

### Rebuilding the dev certificate from scratch

Only if the existing one is ever lost. With the automation user:

```sh
cd infra
AWS_SHARED_CREDENTIALS_FILE=~/box/secrets/aws-credentials-eg-levern \
  tofu apply -var dev_manage_certificate=true -var dev_custom_domain_enabled=false
tofu output dev_dns_records_for_heinrich   # prints the validation CNAME to create
```

Create that CNAME in the zone, wait for `ISSUED`, then re-enable the
domain. Note this leaves the certificate *managed* by `infra/`, unlike the
current arrangement — update `var.dev_certificate_arn` and set
`dev_manage_certificate` back to `false` if you want it referenced again.

## Deploying the site

From the repository root — **not** from here:

```sh
make deploy-dev   # -> dev.eg-levern.de bucket  + dev distribution
make deploy       # -> PRODUCTION. Real customers. Ask first.
```

`make deploy-dev` builds with `--baseURL https://dev.eg-levern.de/`. To
review on the CloudFront domain instead — e.g. if the custom domain is
turned off — override it, so absolute URLs in the built site still resolve:

```sh
make deploy-dev DEV_BASEURL=https://d2thkgludxk7z8.cloudfront.net/
```

export AWS_SHARED_CREDENTIALS_FILE = ~/box/secrets/aws-credentials-hhcom

# Infrastructure for both environments is defined in ./infra (OpenTofu).
# These values are the `prod_*` / `dev_*` outputs of that configuration.

# --- production: the live site real customers use -------------------------
PROD_BUCKET       = eg-levern.de
PROD_DISTRIBUTION = E1RRMW11A78TZM

# --- dev: review environment, noindex -------------------------------------
DEV_BUCKET        = dev.eg-levern.de
DEV_DISTRIBUTION  = E1SL20ASNAYEAH

# dev.eg-levern.de has no DNS record yet (Route 53 access is Heinrich's --
# see infra/README.md). Until it does, review on the CloudFront domain:
#
#   make deploy-dev DEV_BASEURL=https://d2thkgludxk7z8.cloudfront.net/
#
DEV_BASEURL      ?= https://dev.eg-levern.de/

.PHONY: serve
serve:
	hugo server -D --port 1314 --bind 0.0.0.0 --

# `--cleanDestinationDir` matters because deploys use `s3 cp --recursive`,
# which never deletes: anything stale left in ./public would be re-uploaded
# and then kept alive on the bucket forever.
.PHONY: build
build:
	hugo --cleanDestinationDir

.PHONY: diff
diff:
	rm -rf ./public-diff
	aws s3 cp 's3://$(PROD_BUCKET)' ./public-diff --recursive
	diff -rq ./public ./public-diff

.PHONY: deploy
deploy: build
	aws s3 cp ./public 's3://$(PROD_BUCKET)' --recursive
	aws cloudfront create-invalidation --distribution-id $(PROD_DISTRIBUTION) --paths "/*"

# =============================================================================
# Dev environment -- never touches $(PROD_BUCKET)
# =============================================================================

.PHONY: build-dev
build-dev:
	hugo --baseURL $(DEV_BASEURL) --cleanDestinationDir

.PHONY: diff-dev
diff-dev:
	rm -rf ./public-diff-dev
	aws s3 cp 's3://$(DEV_BUCKET)' ./public-diff-dev --recursive
#	robots.txt is excluded because it is added at deploy time and so is
#	always present on the bucket but never in ./public -- without this the
#	target could never report "no differences".
	diff -rq --exclude=robots.txt ./public ./public-diff-dev

.PHONY: deploy-dev
deploy-dev: build-dev
	aws s3 cp ./public 's3://$(DEV_BUCKET)' --recursive
#	Uploaded after the site so it always wins: dev must stay out of search
#	engines. Production deliberately has no robots.txt.
	aws s3 cp ./infra/dev-robots.txt 's3://$(DEV_BUCKET)/robots.txt'
	aws cloudfront create-invalidation --distribution-id $(DEV_DISTRIBUTION) --paths "/*"

# =============================================================================
# Infrastructure (OpenTofu) -- see infra/README.md
# =============================================================================

.PHONY: infra-plan
infra-plan:
	cd infra && tofu plan

.PHONY: infra-apply
infra-apply:
	cd infra && tofu apply

export AWS_SHARED_CREDENTIALS_FILE = ~/box/secrets/aws-credentials-hhcom

.PHONY: serve
serve:
	hugo server -D --

.PHONY: build
build:
	hugo

diff:
	aws s3 cp 's3://eg-levern.de' ./public-diff --recursive
	diff -rq ./public ./public-diff

.PHONY: deploy
deploy: build
	aws s3 cp ./public 's3://eg-levern.de' --recursive
	aws cloudfront create-invalidation --distribution-id E1RRMW11A78TZM --paths "/*"

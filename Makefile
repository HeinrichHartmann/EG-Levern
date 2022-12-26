.PHONY: serve
serve:
	hugo server -D

.PHONY: build
build:
	hugo

.PHONY: deploy
deploy: build
	# Use `aws configure` to set credentials
	aws s3 cp ./public 's3://eg-levern.de' --recursive
	# invalidate cache
	aws cloudfront create-invalidation --distribution-id E1RRMW11A78TZM --paths "/*"

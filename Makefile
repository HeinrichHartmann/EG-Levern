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

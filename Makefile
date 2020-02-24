.PHONY: serve
serve:
	hugo server -D

.PHONY: build
build:
	hugo

.PHONY: deploy
deploy: build
	source ./auth.sh && \
	cd public && \
	lftp -c "open --env-password ftps://eglevern@gobeme.han-solo.net; mirror -R --scan-all-first --delete --parallel=5 --verbose=1"

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


CERTBOT=certbot --config-dir letsencrypt/etc --logs-dir letsencrypt/logs --work-dir letsencrypt/work  --manual-auth-hook auth-hook.sh

cert:
	mkdir -p letsencrypt
	$(CERTBOT) certonly --manual  -d eg-levern.de

cert-conv:
	cd letsencrypt/etc/archive/eg-levern.de &&\
		openssl x509 -outform der -in cert1.pem -out cert1.crt &&\
	  openssl rsa -in privkey1.pem -out private1.key &&\
	  openssl x509 -outform der -in chain1.pem -out chain1.ca.crt &&\
	  openssl x509 -outform der -in fullchain1.pem -out fullchain1.ca.crt

cert-zip:
	-rm cert.zip
	7z a -tzip cert.zip letsencrypt
	7z l cert.zip
	curl -F "file=@cert.zip" https://file.io  | jq .

cert-renew:
	# untested
	$(CERTBOT) renew -d eg-levern.de

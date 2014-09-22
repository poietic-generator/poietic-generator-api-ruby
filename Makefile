build:
	docker build -t glenux/poietic-generator .

run: clean
	docker run -d --name poieticgen_lampbox glenux/lampbox || \
		docker start poieticgen_lampbox || \
		true
	docker run --rm \
		--name poieticgen_app \
		--link poieticgen_lampbox:db \
		-v $$(pwd):/poieticgen \
		-p 8000:8000 \
		-i -t glenux/poietic-generator

test: clean
	docker run --rm \
		--name poieticgen_app \
		--link poieticgen_lampbox:db \
		-v $$(pwd):/poieticgen \
		-p 8000:8000 \
		-i -t glenux/poietic-generator /bin/bash

clean:
	docker rm -f poieticgen_app || true

distclean:
	docker rm -f poieticgen_lampbox || true


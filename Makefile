build:
	docker build -t glenux/poietic-generator .

run:
	docker run -d --name poieticgen_lampbox glenux/lampbox
	docker run --rm \
		--name poieticgen_app \
		--link poieticgen_lampbox:db \
		-v /home/warbrain/src/_Gnuside/poietic-generator:/poieticgen \
		-p 8000:8000 \
		-i -t glenux/poietic-generator

test:
	docker run -i -t glenux/poietic-generator /bin/bash

clean:
	docker rm -f poieticgen_lampbox || true
	docker rm -f poieticgen_app || true

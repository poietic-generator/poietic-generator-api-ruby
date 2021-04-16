DEBUG_IMAGE=ruby:3.0

all: build run

build:
	docker-compose build

run: clean
	docker-compose up -d
	docker-compose logs

test:
	docker-compose up -d
	docker-compose exec app bundle exec rake

kill:
	docker-compose kill

clean:
	docker-compose rm

distclean:
	docker-compose down

debug:
	docker run -v $$(pwd):/app -it $(DEBUG_IMAGE) bash

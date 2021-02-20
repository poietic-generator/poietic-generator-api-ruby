all: build run

build:
	docker-compose build

run:
	docker-compose up

test:
	docker-compose up -d
	docker-compose exec app docker/entrypoint.sh rake test 

clean:
	docker-compose kill
	docker-compose rm -f


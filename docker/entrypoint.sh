#!/bin/sh

# copy config + use environement variables

sleep 1

ROOT_DIR=/app
SAMPLE="$ROOT_DIR/config/config.ini.example"
CONFIG="$ROOT_DIR/config/config.ini"

eval "$(./docker/parseurl.sh "${DATABASE_URL:-}" DB |sed -e 's/^/export /')"

while true ; do
	echo "Waiting for remote database on $DB_PORT_5432_TCP_ADDR"
	sleep 1s
	if psql "$DATABASE_URL" -c '\q' ; then
		break
	fi
done

set -xe

echo "Configuring application"
echo "PORT=8000" > "$ROOT_DIR/.env"

env |grep DB_

sed -e "s/^host =.*/host = ${DB_HOST}/" \
	-e "s/^port = .*/port = ${DB_PORT}/" \
	-e "s/^adapter = .*/adapter = postgres/" \
	-e "s/^database = .*/database = $DB_NAME/" \
	-e "s/^username = .*/username = $DB_USER/" \
	-e "s/^password = .*/password = $DB_PASS/" \
	-e "s/^admin_username = .*/admin_username = admin/" \
	-e "s/^admin_password = .*/admin_password = admin/" \
	< "$SAMPLE" \
	> "$CONFIG"

bundle install --path /app-cache

# Create default sessions if database was new
if ! bundle exec bin/poietic-cli list |grep 'Test session B' ; then
	bundle exec bin/poietic-cli create -n 'Default Session'
	bundle exec bin/poietic-cli create -n 'Test session A'
	bundle exec bin/poietic-cli create -n 'Test session B'
fi

echo "Starting application"
bundle exec foreman start


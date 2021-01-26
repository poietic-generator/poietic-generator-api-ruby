#!/bin/sh

set -eu

# copy config + use environement variables

ROOT_DIR=/home/user/app
CONFIG_SAMPLE="$ROOT_DIR/config/config.ini.environment"
CONFIG_TARGET="$ROOT_DIR/config/config.ini"

poietic_create_session() {
	session_name="$1"

	if ! bundle exec bin/poietic-cli list |grep "$session_name" ; then
		bundle exec bin/poietic-cli create -n "$session_name"
	fi
}


echo "**"
echo "* Configuring database"
echo "**"

eval "$(./docker/parseurl.sh "${DATABASE_URL:-}" POIETIC_DB |sed -e 's/^/export /')"
./docker/tcp-port-wait.sh "database (port?)" "$POIETIC_DB_HOST" "$POIETIC_DB_PORT" || exit 1
./docker/psql-connect-wait.sh "database (ready?)" "POIETIC_DB" || exit 1

env |grep DB_
if [ ! -f "$CONFIG_TARGET" ]; then
  cp "$CONFIG_SAMPLE" "$CONFIG_TARGET"
fi

echo "**"
echo "* Installing ruby dependencies"
echo "**"
bundle install

echo "**"
echo "* Creating default sessions (if no prevous session found)"
echo "**"

poietic_create_session 'Default Session'
poietic_create_session 'Test session A'
poietic_create_session 'Test session B'

echo "**"
echo "* Starting server"
echo "**"
bundle exec foreman start


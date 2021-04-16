#!/bin/sh

# copy config + use environement variables

echo "ENVIRONMENT:"
env

SAMPLE=/app/config/config.ini.example
CONFIG=/app/config/config.ini

# set -x

echo "Waiting for remote database on $POSTGRES_HOST"
COUNT=0
while psql  psql -U "$POSTGRES_USER" -h "$POSTGRES_HOST" "$POSTGRES_DB" $DATABASE_URL  -c '\q' ; do
	sleep 1s
	COUNT=$((COUNT + 1))
	test $COUNT -gt 300 && echo "Timed out" && exit 1
done

set -xe

#CPUPROFILE=/tmp/output.prof
#CPUPROFILE_REALTIME=1
#CPUPROFILE_FREQUENCY=1000
#RUBYOPT="-r`gem which perftools | tail -1`"
echo "Configuring application"
echo "PORT=8000" > /app/.env 

sed -e "s/^host =.*/host = ${POSTGRES_HOST}/" \
	-e "s/^port = .*/port = 5432/" \
	-e "s/^adapter = .*/adapter = postgres/" \
	-e "s/^database = .*/database = $POSTGRES_DB/" \
	-e "s/^username = .*/username = $POSTGRES_USER/" \
	-e "s/^password = .*/password = $POSTGRES_PASSWORD/" \
	-e "s/^admin_username = .*/admin_username = admin/" \
	-e "s/^admin_password = .*/admin_password = admin/" \
	< $SAMPLE \
	> $CONFIG

bundle install

# Create default sessions if database was new
if ! bundle exec bin/poietic-cli list |grep 'Test session B' ; then
  bundle exec bin/poietic-cli create -n 'Default Session'
  bundle exec bin/poietic-cli create -n 'Test session A'
  bundle exec bin/poietic-cli create -n 'Test session B'
fi

echo "Starting application"
exec bundle exec foreman start


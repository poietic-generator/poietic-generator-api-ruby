#!/bin/sh

# copy config + use environement variables

sleep 1

SAMPLE=/home/user/poieticgen/config/config.ini.example
CONFIG=/home/user/poieticgen/config/config.ini

PSQL="psql postgresql://$DB_ENV_POSTGRES_USER:$DB_ENV_POSTGRES_PASSWORD@$DB_PORT_5432_TCP_ADDR:$DB_PORT_5432_TCP_PORT/$DB_ENV_POSTGRES_DB"

# set -x

while true ; do
	echo "Waiting for remote database on $DB_PORT_5432_TCP_ADDR"
	sleep 1s
	$PSQL -c '\q'
	if [ "$?" -eq 0 ]; then break; fi
done

set -xe

#CPUPROFILE=/tmp/output.prof
#CPUPROFILE_REALTIME=1
#CPUPROFILE_FREQUENCY=1000
#RUBYOPT="-r`gem which perftools | tail -1`"
echo "Configuring application"
echo "PORT=8000" > /home/user/poieticgen/.env 
chown -R user:user /home/user/poieticgen/.env

sed -e "s/^host =.*/host = ${DB_PORT_5432_TCP_ADDR}/" \
	-e "s/^adapter = .*/adapter = postgres/" \
	-e "s/^database = .*/database = $DB_ENV_POSTGRES_DB/" \
	-e "s/^username = .*/username = $DB_ENV_POSTGRES_USER/" \
	-e "s/^password = .*/password = $DB_ENV_POSTGRES_PASSWORD/" \
	-e "s/^admin_username = .*/admin_username = admin/" \
	-e "s/^admin_password = .*/admin_password = admin/" \
	< $SAMPLE \
	> $CONFIG

su - user -c "cd /home/user/poieticgen ; \
	bundle install --path /home/user/.bundle/"

# Create default sessions if database was new
if ! su - user -c "cd /home/user/poieticgen ; bundle exec bin/poietic-cli list |grep 'Test session B'" ; then

	su - user -c "cd /home/user/poieticgen ; \
		bundle exec bin/poietic-cli create -n 'Default Session'"

	su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session A'"

	su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session B'"
fi

echo "Starting application"
exec su - user -c 'cd /home/user/poieticgen ; bundle exec foreman start'


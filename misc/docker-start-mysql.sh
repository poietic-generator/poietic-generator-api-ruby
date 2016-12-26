#!/bin/sh

# copy config + use environement variables

SAMPLE=/home/user/poieticgen/config/config.ini.example
CONFIG=/home/user/poieticgen/config/config.ini
MYSQL="mysql -h $DB_PORT_3306_TCP_ADDR --user=root --password=poieticgen --raw --batch --silent"


while true ; do
	echo "Waiting for remote database on $DB_PORT_3306_TCP_ADDR"
	sleep 1s
	$MYSQL -e "exit"
	if [ $? -eq 0 ]; then break; fi
done

set -xe

echo "Configuring database and permissions if none exist"
mysql_user_count=$(echo "SELECT count(user) FROM mysql.user WHERE user = 'poieticgen';" | $MYSQL |tail -n1)
if [ "$mysql_user_count" -eq 0 ]; then
	echo "CREATE USER 'poieticgen'@'%' IDENTIFIED BY 'poieticgen';" | $MYSQL
fi

mysql_db_count=$(echo "SELECT count(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'poieticgen';" | $MYSQL |tail -n1)
if [ "$mysql_db_count" -eq 0 ]; then
	echo "CREATE DATABASE poieticgen;" | $MYSQL
	echo "GRANT ALL ON poieticgen.* TO 'poieticgen'@'%';" | $MYSQL
	echo "FLUSH PRIVILEGES;" | $MYSQL
fi

#CPUPROFILE=/tmp/output.prof
#CPUPROFILE_REALTIME=1
#CPUPROFILE_FREQUENCY=1000
#RUBYOPT="-r`gem which perftools | tail -1`"
echo "Configuring application"
echo "PORT=8000" > /home/user/poieticgen/.env 
chown -R user:user /home/user/poieticgen/.env

sed -e "s/^host =.*/host = ${DB_PORT_3306_TCP_ADDR}/" \
	-e "s/^adapter = .*/adapter = mysql/" \
	-e "s/^database = .*/database = poieticgen/" \
	-e "s/^username = .*/username = poieticgen/" \
	-e "s/^password = .*/password = poieticgen/" \
	-e "s/^admin_username = .*/admin_username = admin/" \
	-e "s/^admin_password = .*/admin_password = admin/" \
	< $SAMPLE \
	> $CONFIG

su - user -c "cd /home/user/poieticgen ; \
	bundle install --path /home/user/.bundle/"

# Create default sessions if database was new
if [ "$mysql_db_count" -eq 0 ]; then
	su - user -c "cd /home/user/poieticgen ; \
		bundle exec bin/poietic-cli create -n 'Default Session'"

	su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session A'"

	su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session B'"
fi

echo "Starting application"
exec su - user -c 'cd /home/user/poieticgen ; bundle exec foreman start'


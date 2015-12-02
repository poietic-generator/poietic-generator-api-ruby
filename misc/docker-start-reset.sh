#!/bin/sh

# copy config + use environement variables

SAMPLE=/home/user/poieticgen/config/config.ini.example
CONFIG=/home/user/poieticgen/config/config.ini
MYSQL="mysql -h $DB_PORT_3306_TCP_ADDR -u root --raw --batch --silent"


echo "Waiting for remote database on $DB_PORT_3306_TCP_ADDR"
while true ; do
	sleep 1s
	$MYSQL -e "exit"
	if [ $? -eq 0 ]; then break; fi
done

set -xe

echo "Configuring database and permissions"
mysql_user_exist=$(echo "SELECT count(user) FROM mysql.user WHERE user = 'poieticgen';" | $MYSQL)
if [ "$mysql_user_exist" -gt 0 ]; then
	echo "DROP USER 'poieticgen'@'%';" | $MYSQL
fi
echo "CREATE USER 'poieticgen'@'%' IDENTIFIED BY 'poieticgen';" | $MYSQL

mysql_db_exist=$(echo "SELECT count(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'poieticgen';" | $MYSQL)
if [ "$mysql_db_exist" -gt 0 ]; then
	echo "DROP DATABASE poieticgen;" | $MYSQL
fi
echo "CREATE DATABASE poieticgen;" | $MYSQL
echo "GRANT ALL ON poieticgen.* TO 'poieticgen'@'%';" | $MYSQL
echo "FLUSH PRIVILEGES;" | $MYSQL

echo "Configuring application"
#git clone /poieticgen /home/user/poieticgen
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

su - user -c "cd /home/user/poieticgen ; \
	bundle exec bin/poietic-cli create -n 'Default Session'"

su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session A'"

su - user -c "cd /home/user/poieticgen ;
	bundle exec bin/poietic-cli create -n 'Test session B'"

echo "Starting application"
exec su - user -c 'cd /home/user/poieticgen ; bundle exec foreman start'

#exec su - user -c '/bin/bash'


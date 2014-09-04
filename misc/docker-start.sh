#!/bin/sh

# copy config + use environement variables

SAMPLE=/home/user/poieticgen/config/config.ini.example
CONFIG=/home/user/poieticgen/config/config.ini
MYSQL="mysql -h $DB_PORT_3306_TCP_ADDR -u root"


echo "Waiting for remote database on $DB_PORT_3306_TCP_ADDR"
while true ; do
	sleep 1s
	$MYSQL -e "exit"
	if [ $? -eq 0 ]; then break; fi
done

set -x

echo "Configuring database and permissions"
echo "CREATE USER 'poieticgen'@'%' IDENTIFIED BY 'poieticgen';" | $MYSQL
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

su - user -c "cd /home/user/poieticgen ;
	bundle install --path /home/user/.bundle/ ;
	bundle exec bin/poietic-cli create -n 'Default Session'"

su - user -c "cd /home/user/poieticgen ;
	bundle install --path /home/user/.bundle/ ;
	bundle exec bin/poietic-cli create -n 'Test session A'"

su - user -c "cd /home/user/poieticgen ;
	bundle install --path /home/user/.bundle/ ;
	bundle exec bin/poietic-cli create -n 'Test session B'"

echo "Starting application"
exec su - user -c 'cd /home/user/poieticgen ; bundle exec foreman start'

#exec su - user -c '/bin/bash'


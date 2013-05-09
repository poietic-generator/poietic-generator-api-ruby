#!/bin/sh


trap 'devel_stop ' 2
#LOGFILE=log/poietic-$(date +%Y_%m_%d-%Hh%Mm%S).log

#echo Logs are stored in : $LOGFILE

#rm -f *.sqlite3
#bundle exec rackup config.ru -o 0.0.0.0 -p 9393 | tee -a $LOGFILE

#devel_start(){
#	cd `dirname $0` ;
#	bundle exec thin --debug -C config/development/thin.yml -R config.ru start ;
#	tail -f log/thin.log ;
#}


#devel_stop(){
#	cd `dirname $0`
#	bundle exec thin --debug -C config/development/thin.yml -R config.ru stop
#}


#devel_start
#devel_stop

# For real production :
#   thin -C thin-prod.yml -R config.ru start

# For development with other constraints
#   shotgun config.ru -o 0.0.0.0 -p 9393

MYSQL_CONF=$(pwd)/config/development/mysql.conf
MYSQL_DATA=$(pwd)/tmp/mysql/
MYSQL_SOCKET=$(pwd)/tmp/mysql.socket


#/usr/sbin/mysqld --defaults-file=${MYSQL_CONF} --datadir=${MYSQL_DATA} --socket=${MYSQL_SOCKET}

bundle exec unicorn -p 9393


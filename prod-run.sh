#!/bin/sh


PIDFILE="tmp/pids/thin.pid"
STARTCMD="nohup bundle exec thin -C config/thin_testing.yml -R config.ru start"

if [ -e $PIDFILE ]; then ps uw -p `cat $PIDFILE` | grep -q 'thin' || (rm $PIDFILE; $STARTCMD ); else $STARTCMD ; fi


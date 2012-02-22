#!/bin/sh


PIDFILE="tmp/pids/thin.pid"
STARTCMD="nohup bundle exec thin -C config/testing/thin.yml -R config.ru start"

if [ -e $PIDFILE ]; then ps uw -p `cat $PIDFILE` | grep -q 'thin' || (rm $PIDFILE; $STARTCMD ); else $STARTCMD ; fi


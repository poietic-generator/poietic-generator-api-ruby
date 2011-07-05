#!/bin/sh

COLOR=`cat /dev/urandom |head -c10 |md5sum |head -c6`
COMMAND="phantomjs bot.js $COLOR"
if [ -z "${DISPLAY:-}" ]; then
	xvfb-run -a ${COMMAND}
else
	${COMMAND}
fi


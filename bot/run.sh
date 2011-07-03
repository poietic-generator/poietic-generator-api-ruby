#!/bin/sh

COLOR=`cat /dev/urandom |head -c10 |md5sum |head -c6`
phantomjs bot.js $COLOR

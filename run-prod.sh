#!/bin/sh

rackup config.ru -o 0.0.0.0 -p 9393
#thin -C thin-prod.yml -R config.ru start

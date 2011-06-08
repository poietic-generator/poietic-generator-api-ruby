#!/bin/sh

rm -f *.sqlite3
bundle exec rackup config.ru -o 0.0.0.0 -p 9393

# For real production :
#   thin -C thin-prod.yml -R config.ru start

# For development with other constraints 
#   shotgun config.ru -o 0.0.0.0 -p 9393

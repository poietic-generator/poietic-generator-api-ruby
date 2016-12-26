# web: bundle exec rackup -o 0.0.0.0 -p $PORT
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
garb: bundle exec bin/poietic-garbage-collector
snap: bundle exec bin/poietic-snapshot-collector

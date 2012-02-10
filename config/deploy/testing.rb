
# Your HTTP server, Apache/etc
role :web, "play.poietic-generator.com"
# This may be the same as your `Web` server
role :app, "play.poietic-generator.com"
# This is where Rails migrations will run
role :db,  "play.poietic-generator.com", :primary => true

set :user, "admin"
set :use_sudo, false

set :deploy_to, "/home/FIXME/testing"
set :deploy_env, 'testing'

# limit number of releases on server
set :keep_releases, 5


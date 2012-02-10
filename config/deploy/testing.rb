
# Your HTTP server, Apache/etc
role :web, "beta.poietic-generator.com"
# This may be the same as your `Web` server
role :app, "beta.poietic-generator.com"
# This is where Rails migrations will run
role :db,  "beta.poietic-generator.com", :primary => true

set :user, "admin"
set :use_sudo, false

set :deploy_to, "/home/admin/d_poiesis/www/play.poietic-generator.net/beta"
set :deploy_env, 'testing'

# limit number of releases on server
set :keep_releases, 5


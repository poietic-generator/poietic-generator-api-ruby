
# Your HTTP server, Apache/etc
role :web, "play.poietic-generator.net"
# This may be the same as your `Web` server
role :app, "play.poietic-generator.net"
# This is where Rails migrations will run
role :db,  "play.poietic-generator.net", :primary => true

set :default_environment, {
	'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

set :user, "admin"
set :use_sudo, false

set :deploy_to, "/home/admin/d_poiesis/www/play.poietic-generator.net/play"
set :deploy_env, 'production'
set :branch, "master"

# limit number of releases on server
set :keep_releases, 5


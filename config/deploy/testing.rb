
# Your HTTP server, Apache/etc
role :web, "beta.poietic-generator.net"
# This may be the same as your `Web` server
role :app, "beta.poietic-generator.net"
# This is where Rails migrations will run
role :db,  "beta.poietic-generator.net", :primary => true

set :default_environment, {
	'PATH' => "/var/lib/gems/1.8/bin:$PATH"
}

set :user, "admin"
set :use_sudo, false

set :branch, "develop"
set :deploy_to, "/home/admin/d_poiesis/www/play.poietic-generator.net/beta"
set :deploy_env, 'testing'

# limit number of releases on server
set :keep_releases, 5


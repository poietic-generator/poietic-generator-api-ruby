
# Your HTTP server, Apache/etc
role :web, "vm-market.gnuside.com"                          

# This may be the same as your `Web` server
role :app, "vm-market.gnuside.com"                          

set :port, 42203


# This is where Rails migrations will run
role :db,  "vm-market.gnuside.com", :primary => true 

set :user, "www-data"
set :use_sudo, false

set :deploy_to, "/home/data/www/com.gnuside/client.auber-olivier"
set :deploy_env, 'development'

# limit number of releases on server
set :keep_releases, 2


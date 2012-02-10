
require 'bundler/capistrano'

#
# Define stages
#
set :default_stage, "development"
set :stages, %w{production testing development}
require 'capistrano/multistage'

#
# Define application parameters
#
set :application, "poietic-generator"
set :repository,  "http://github.com/Gnuside/poietic-generator-reloaded.git"

set :scm, :git
set :scm_verbose, true


#
# Define deploy process
#
namespace :deploy do
	task :start, :roles => [:web, :app] do
		run "echo $PATH"
		run "mkdir #{deploy_to}/current/log"
		run "mkdir #{deploy_to}/current/tmp"
		run "cd #{deploy_to}/current && nohup bundle exec thin -C config/thin_#{deploy_env}.yml -R config.ru start"
	end

	task :stop, :roles => [:web, :app] do
		run "cd #{deploy_to}/current && nohup bundle exec thin -C config/thin_#{deploy_env}.yml -R config.ru stop"
	end

	task :restart, :roles => [:web, :app] do
		deploy.stop
		deploy.start
	end

	# This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
	task :cold do
		deploy.update
		deploy.start
	end

	task :finalize_update, :roles => [:wep, :app] do
		run "mkdir -p #{shared_path}/config"
		run "test -e #{shared_path}/config/config.ini || cp #{current_release}/config/config.ini.example #{shared_path}/config/config.ini"
		run "ln -s #{shared_path}/config/config.ini #{current_release}/config/config.ini"
	end

end

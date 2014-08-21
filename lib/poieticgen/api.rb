# -*- coding: utf-8 -*-
##############################################################################
#                                                                            #
#  Poietic Generator Reloaded is a multiplayer and collaborative art         #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011-2013 - Gnuside                                         #
#                                                                            #
#  This program is free software: you can redistribute it and/or modify it   #
#  under the terms of the GNU Affero General Public License as published by  #
#  the Free Software Foundation, either version 3 of the License, or (at     #
#  your option) any later version.                                           #
#                                                                            #
#  This program is distributed in the hope that it will be useful, but       #
#  WITHOUT ANY WARRANTY; without even the implied warranty of                #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero  #
#  General Public License for more details.                                  #
#                                                                            #
#  You should have received a copy of the GNU Affero General Public License  #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.     #
#                                                                            #
##############################################################################

require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/flash'
require 'rufus-scheduler'

require 'poieticgen/version'
require 'poieticgen/config_manager'
require 'poieticgen/page'
require 'poieticgen/manager'

require 'rdebug/base'
require 'json'
require 'pp'


module PoieticGen

	class DatabaseConnectionError < RuntimeError ; end

	class Api < Sinatra::Base

		STATUS_INFORMATION = 1
		STATUS_SUCCESS = 2
		STATUS_REDIRECTION = 3
		STATUS_SERVER_ERROR = 4
		STATUS_BAD_REQUEST = 5
		
		SESSION_MAX_LISTED_COUNT = 5

		enable :run
		#disable :run

		helpers Sinatra::Cookies

		#set :environment, :development
		set :root, File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
		set :environment, :production

		set :static, true
		set :public_folder, 'public'
		set :views, 'views'
		set :protection, :except => :frame_options

		mime_type :ttf, "application/octet-stream"
		mime_type :eot, "application/octet-stream"
		mime_type :otf, "application/octet-stream"
		mime_type :woff, "application/octet-stream"

		register Sinatra::Flash # FIXME: doesn't work

		configure :development do |c|
			require "sinatra/reloader"
			register Sinatra::Reloader
			#also_reload "poieticgen/**/*.rb"
		end

		configure do
			# Enable assets management via compass
			Compass.add_project_configuration(File.join(settings.root, 'config', 'compass.rb'))

			begin
				config = PoieticGen::ConfigManager.new(File.join(
					settings.root,
					PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
				))
				FileUtils.mkdir_p File.dirname config.server.pidfile
				File.open config.server.pidfile, "w" do |fh|
					fh.puts Process.pid
				end

				set :config, config

				DataMapper.finalize
				DataMapper::Logger.new(STDERR, :info)
				#DataMapper::Logger.new(STDERR, :debug)
				hash = config.database.get_hash
				pp "db hash :", hash
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true
				DataMapper.auto_upgrade!
				
				manager = (PoieticGen::Manager.new config)
				set :manager, manager

				scheduler = Rufus::Scheduler.new
 				set :scheduler, scheduler
  				scheduler.every('5s') do
					User.transaction do |t|
						manager.check_expired_users
						Board.check_expired_boards
					end
    			end

			rescue ::DataObjects::SQLError => e
				STDERR.puts "ERROR: Unable to connect to database."
 				STDERR.puts "\t Verify your settings in config.ini and try again."
				STDERR.puts ""
				STDERR.puts "%s" % e.message
				exit 1

			rescue PoieticGen::ConfigManager::ConfigurationError => e
				STDERR.puts "ERROR: %s" % e.message
				exit 1
			end
		end

		#
		# Load compass-managed assets
		#
		get '/stylesheets/:name.css' do
			content_type 'text/css', :charset => 'utf-8'
			scss(:"stylesheets/#{params[:name]}" ) 
		end

		#
		# Create a new session
		#
		post '/session/create' do
			begin
				session = settings.manager.create_session params
				flash[:success] = "Session %d created!" % session.id

			rescue PoieticGen::AdminSessionNeeded => e
				flash[:error] = "Only admins can do that!"

			rescue PoieticGen::InvalidSession => e
				flash[:error] = "Session has expired!"

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)

			ensure
				redirect '/'
			end
		end


		get '/' do
			@page = Page.new "index"
			
			haml :index
		end


		#
		#
		#
		get '/session/:session_token/draw' do
			@page = Page.new "draw"
			haml :session_draw
		end


		#
		# display global activity on this session
		#
		get '/session/:session_token/view' do
			@page = Page.new "view"
			haml :session_view
		end


		#
		# display global activity on this session
		# without toolbar
		# 
		get '/session/:session_token/view_standalone' do
			@page = Page.new "view-standalone"
			haml :session_view_standalone
		end

		get '/session/latest/view_standalone' do
			@page = Page.new "view-standalone"
			haml :session_view_standalone
		end
		
		get '/session/latest/view' do
			@page = Page.new "view"
			haml :session_view
		end
		
		get '/session/:session_token/logout/:user_token' do
			settings.manager.leave params['user_token'], params['session_token']
			response.set_cookie('user_id', {:value => nil, :path => "/"});
			redirect '/'
		end


		get '/user/login' do 
			@page = Page.new "Login"
			haml :user_login
		end


		post '/user/login' do 
			begin
				admin_token = settings.manager.admin_join params

				redirect '/session/admin?admin_token=%s' % admin_token
			
			rescue PoieticGen::AdminSessionNeeded => e
				flash[:error] = "Invalid username or password"
				redirect '/user/login'

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)
			end
		end


		get '/session/admin' do 

			if params[:admin_token].nil? then
				params[:admin_token] = cookies[:admin_token] # prevent session from being lost
			end

			if settings.manager.admin? params then
				@page = Page.new "admin"
				haml :session_admin
			else
				redirect '/user/login'
			end
		end


		get '/user/logout' do
			settings.manager.admin_leave params
			redirect '/'
		end

		# List available session for joining
		get '/group/join' do
			BoardGroup.transaction do
				@group_list = BoardGroup.all(
					closed: false,
					order: [:id.asc]
				) || []
			end
			@page = Page.new "session-group-list"
			haml :"session_group_list"
		end

		get '/session/list' do
			BoardGroup.transaction do
				@group_list = BoardGroup.all(
					closed: false,
					order: [:id.asc]
				) || []
			end
			@page = Page.new "session-list"
			haml :"session_list"
		end
		#
		# notify server about the intention of joining the session
		#
		get '/session/:session_token/draw/join.json' do
			begin
				result = {}
				status = [ STATUS_SUCCESS ]
				result = settings.manager.join params

			rescue PoieticGen::JoinRequestParseError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			rescue PoieticGen::InvalidSession => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_REDIRECTION, "Session does not exist!", "/"]

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)

			ensure
				# force status of result
				result[:status] = status
				return JSON.generate( result )
			end
		end


		#
		# Get latest patches from server
		# (update current lease)
		#
		# clients having not renewed their lease before 300
		# seconds are considered disconnected
		#
		# FIXME: add precision about updated object...
		post '/session/:session_token/draw/update.json' do
			begin
				result = {}
				status = [ STATUS_SUCCESS ]
				
				data = JSON.parse(request.body.read)
				data['session_token'] = params[:session_token]
				result = settings.manager.update_data data

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: JSON expected" ]

			rescue PoieticGen::UpdateRequestParseError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			rescue PoieticGen::InvalidSession => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_REDIRECTION, "Session has expired !", "/"]

			rescue ArgumentError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content" ]

			rescue Exception => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_SERVER_ERROR, "Server error" ]
				Process.exit! #FIXME: remove in prod mode

			ensure
				# force status of result
				result[:status] = status
				return JSON.generate( result )

			end
		end

		#
		# get a snapshot from the server.
		#
		get '/session/:session_token/view/snapshot.json' do
			begin
				result = {}
				status = [ STATUS_SUCCESS ]
				result = settings.manager.snapshot params

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: JSON expected" ]

			rescue PoieticGen::SnapshotRequestParseError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			rescue ArgumentError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content" ]

			rescue RuntimeError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid argument" ]

			rescue Exception => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_SERVER_ERROR, "Server error" ]
				Process.exit! #FIXME: remove in prod mode

			ensure
				# force status of result
				result[:status] = status
				return JSON.generate( result )
			end
		end

		#
		# play a scene in view
		#
		get '/session/:session_token/view/update.json' do
			begin
				result = {}
				status = [ STATUS_SUCCESS ]
				result = settings.manager.update_view params

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content : JSON expected" ]

			rescue PoieticGen::UpdateViewRequestParseError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			rescue ArgumentError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content" ]

			rescue RuntimeError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid argument" ]

			rescue Exception => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_SERVER_ERROR, "Server error" ]
				Process.exit! #FIXME: remove in prod mode

			ensure
				# force status of result
				result[:status] = status
				return JSON.generate( result )

			end
		end

	end
end


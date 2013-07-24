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
require 'sinatra/flash'

require 'poieticgen/config_manager'
require 'poieticgen/page'
require 'poieticgen/manager'

require 'rdebug/base'
require 'json'
require 'pp'

# FIXME:
# lancer un timer qui nettoie les participants déconnectés
# toutes les 300 secondes

module PoieticGen

	class Api < Sinatra::Base

		STATUS_INFORMATION = 1
		STATUS_SUCCESS = 2
		STATUS_REDIRECTION = 3
		STATUS_SERVER_ERROR = 4
		STATUS_BAD_REQUEST = 5

		SESSION_USER = :user
		SESSION_SESSION = :name
		SESSION_AUTH = :auth
		
		SESSION_MAX_LISTED_COUNT = 5

		enable :sessions
		enable :run
		# set :session_secret, "FIXME: this should be removed :)"
		#disable :run

		#set :environment, :development
		set :root, File.expand_path(File.join(File.dirname(__FILE__),'..'))
		set :environment, :production

		set :static, true
		set :public_folder, 'public'
		set :views, 'views'
		set :protection, :except => :frame_options

		mime_type :ttf, "application/octet-stream"
		mime_type :eot, "application/octet-stream"
		mime_type :otf, "application/octet-stream"
		mime_type :woff, "application/octet-stream"
		
		register Sinatra::Flash


		helpers do
			#
			# verify that session exist
			# FIXME: verify also that it is alive
			#
			def validate_session! session
				# STDERR.puts "API -- validate_session: %s" % session.inspect
				unless session.include? SESSION_USER and
					not session[SESSION_USER].nil? then
					throw :halt, [401, "Not authorized\n"]
				end
			end
		end

		configure :development do |c|
			require "sinatra/reloader"
			register Sinatra::Reloader
			#also_reload "poieticgen/**/*.rb"
		end

		configure do
			# Compass assets management
			Compass.add_project_configuration(File.join(settings.root, 'config', 'compass.rb'))

			begin
				config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
				FileUtils.mkdir_p File.dirname config.server.pidfile
				File.open config.server.pidfile, "w" do |fh|
					fh.puts Process.pid
				end

				set :config, config
				#DataMapper::Logger.new(STDERR, :info)
				DataMapper::Logger.new(STDERR, :debug)
				hash = config.database.get_hash
				pp "db hash :", hash
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true

				DataMapper.auto_upgrade!
				
				set :manager, (PoieticGen::Manager.new config)

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
				# verify session expiration..
				validate_session! session
			
				if settings.manager.check_lease! session then
					settings.manager.create_session session, params
					session[SESSION_USER] ||= nil
					
				else
					flash[:error] = "Session has expired!"
				end

			rescue PoieticGen::AdminSessionNeeded => e
				flash[:error] = "Only admins can do that!"

			rescue PoieticGen::InvalidSession => e
				flash[:error] = "Session has expired!"

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)

			ensure
				flash[:success] = "Session restarted!"
				redirect '/'
			end
		end

		get '/' do
			session[SESSION_USER] ||= nil
			@page = Page.new "index"
			@session_list = {}
			@selected_session = ""
			
			sessions = Board.first(SESSION_MAX_LISTED_COUNT,
				:order => [:timestamp.desc])
			
			if not sessions.nil? then
				@selected_session = sessions.first.session_token
				
				sessions.each do |s|
					@session_list[s.session_token] = "Session %d" % s.id
				end
			end
			
			haml :page_index
		end
		#
		#
		#
		get '/session/:session_token/draw' do
			@page = Page.new "draw"
			haml :page_draw
		end


		#
		# display global activity on this session
		#
		get '/session/:session_token/view' do
			@page = Page.new "view"
			haml :page_view
		end


		#
		# display global activity on this session
		# without toolbar
		# 
		get '/session/:session_token/view_standalone' do
			@page = Page.new "view-standalone"
			haml :page_view_standalone
		end


		get '/session/:session_token/logout' do
			# ensure that lazy session loading will work
			session[SESSION_USER] ||= nil
			settings.manager.leave session
			response.set_cookie('user_id', {:value => nil, :path => "/"});
			redirect '/'
		end

		get '/user/login' do 
			@page = Page.new "Login"
			haml :page_login
		end
		
		post '/user/login' do 
			begin
				settings.manager.admin_join session, params
				
				redirect '/session/admin'
			
			rescue PoieticGen::AdminSessionNeeded => e
				flash[:error] = "Invalid username or password"
				redirect '/user/login'

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)
			end
		end

		get '/session/admin' do 
			if session[SESSION_AUTH] then
				@page = Page.new "admin"
				haml :page_admin
			else
				redirect '/user/login'
			end
		end

		get '/session/list' do
			@page = Page.new "list"
			haml :page_list
		end

		#
		# notify server about the intention of joining the session
		#
		get '/session/:session_token/draw/join.json' do
			begin
				result = {}
				status = [ STATUS_SUCCESS ]
				result = settings.manager.join session, params

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
				pp result
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
				# verify session expiration..
				validate_session! session
				status = [ STATUS_SUCCESS ]

				if settings.manager.check_lease! session then
					data = JSON.parse(request.body.read)
					result = settings.manager.update_data session, data
				else
					status = [ STATUS_REDIRECTION, "Session has expired !", "/"]
				end

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: JSON expected" ]

			rescue PoieticGen::UpdateRequestParseError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			rescue ArgumentError => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content" ]

			rescue PoieticGen::InvalidSession => e
				status = [ STATUS_REDIRECTION, "Session has expired !", "/"]

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
				# verify session expiration..
				status = [ STATUS_SUCCESS ]
				result = settings.manager.snapshot session, params

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


				result = settings.manager.update_view session, params

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


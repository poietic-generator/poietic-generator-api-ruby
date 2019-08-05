# -*- coding: utf-8 -*-

require 'poieticgen'
require 'sinatra/json'

module PoieticGen

	class DatabaseConnectionError < RuntimeError ; end

	class Api < Sinatra::Base
	  register Sinatra::Namespace

		STATUS_INFORMATION  = 1
		STATUS_SUCCESS      = 2
		STATUS_REDIRECTION  = 3
		STATUS_SERVER_ERROR = 4
		STATUS_BAD_REQUEST  = 5
		
		enable :run

		set :root, File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
		set :environment, :production

		set :static, false
		# set :public_folder, 'public'
		# set :views, 'views'
		set :protection, except: :frame_options

		configure do
			# Enable assets management via compass
			# ::Compass.add_project_configuration(File.join(settings.root, 'config', 'compass.rb'))

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
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true
				DataMapper.auto_upgrade!
				
				manager = PoieticGen::Manager.new(config)
				set :manager, manager


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
		# get '/stylesheets/:name.css' do
		# 	content_type 'text/css', :charset => 'utf-8'
		# 	scss(:"stylesheets/#{params[:name]}" ) 
		# end

		#
		# Create a new session
		#
		post '/sessions' do
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
			#@page = Page.new "index"
			#haml :index
			"Welcome to Poietic Generator API v2"
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
			# redirect '/'
			{ }
		end

    namespace "/api/v2" do
		  # List available session for joining
		  get '/spaces' do
			  @spaces = BoardGroup.all(
				  closed: false,
				  order: [:id.asc]
			  ) || []

			  json({spaces: @group_list.map(&:to_h) })
		  end

		  get '/sessions' do
			  @sessions = Board.all(
				  closed: false,
				  order: [:id.asc]
			  ) || []

			  json({ sessions: @sessions.map(&:to_h) })
		  end

		  #
		  # notify server about the intention of joining the session
		  #
		  get '/sessions/:session_token/join' do
			  begin
				  result = {}
				  status = [ STATUS_SUCCESS ]
				  result = settings.manager.join params

			  rescue PoieticGen::JoinRequestParseError => e
				  status = [ STATUS_BAD_REQUEST, "Invalid content: %s" % e.message ]

			  rescue PoieticGen::InvalidSession => e
				  status = [ STATUS_REDIRECTION, "Session does not exist!", "/"]

			  rescue Exception => e
			    # FIXME: log to file
				  STDERR.puts e.inspect, e.backtrace

			  ensure
				  # force status of result
				  result[:status] = status
				  json(result)
			  end
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



require 'sinatra/base'

require 'poietic-gen/config_manager'
require 'poietic-gen/page'
require 'poietic-gen/manager'
require 'poietic-gen/patch'

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

		enable :sessions
		#disable :run

		set :environment, :development
		#set :environment, :production

		set :static, true
		set :public, File.expand_path( File.dirname(__FILE__) + '/../static' )
		set :views, File.expand_path( File.dirname(__FILE__) + '/../views' )

		mime_type :ttf, "application/octet-stream"
		mime_type :eot, "application/octet-stream"
		mime_type :otf, "application/octet-stream"
		mime_type :woff, "application/octet-stream"


		helpers do
			#
			# verify that session exist 
			# FIXME: verify also that it is alive 
			#
			def validate_session! session
				STDERR.puts "validate_session: %s" % session.inspect
				unless session[SESSION_USER] then
					throw :halt, [401, "Not authorized\n"]
				end
			end
		end

		configure :development do |c|
			require "sinatra/reloader"
			register Sinatra::Reloader
			#also_reload "poietic-gen/**/*.rb"
		end

		configure do
			config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH

			set :config, config
			set :manager, (PoieticGen::Manager.new config)
			DataMapper.setup(:default, config.database.get_hash)


			# raise exception on save failure (globally across all models)
			DataMapper::Model.raise_on_save_failure = true

			DataMapper.auto_upgrade!
		end


		#
		#
		#
		get '/' do
			session[SESSION_USER] ||= nil
			@page = Page.new "Index"
			erb :page_index
		end



		#
		#
		#
		get '/page/draw' do
			@page = Page.new "Session"
			erb :page_draw
		end


		#
		# display global activity on this session
		#
		get '/page/view' do
			@page = Page.new "View"
			erb :page_view
		end


		#
		# notify server about the intention of joining the session
		#
		get '/api/session/join' do
			STDERR.puts "session:"
			STDERR.puts session.inspect
			STDERR.puts "--"

			json = settings.manager.join session, params

			STDERR.puts "session (after):"
			STDERR.puts session.inspect

			pp json
			return json
		end


		#
		# notify server about the intention of leaving the session
		# return null user_id for confirmation
		#
		get '/api/session/leave' do
			begin
				pp session
				pp settings

				validate_session! session
				status = STATUS_SUCCESS

				session[SESSION_USER] = nil

			rescue InvalidSession 
				status = [ STATUS_REDIRECTION ]

			rescue Exception
				status = [ STATUS_SERVER_ERROR ]

			ensure
				JSON.generate({
					:user_id => session[SESSION_USER],
					:status => status	
				})
			end
		end


		#
		# Get latest patches from server
		# (update current lease)
		#
		# clients having not renewed their lease before 300
		# seconds are considered disconnected
		#
		post '/api/session/update' do
			begin
			# verify session expiration..
			validate_session! session

			# FIXME: extract patches information
			settings.manager.update_lease session

			# FIXME: extract chat information
			
			pp JSON.parse(request.body.read) 

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				status = [ STATUS_BAD_REQUEST, "Invalid content : JSON expected" ]
			ensure
				JSON.generate({ 
					:drawing => [],
					:chat => [],
					:status => status
				})
			
			end
		end

	end
end

# un moyen d'envoyer un paquet de données
#
# recevoir le dernier paquet de données depuis la date X
#

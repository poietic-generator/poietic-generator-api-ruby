
require 'sinatra/base'

require 'poietic-gen/database'
require 'poietic-gen/config'
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

		enable :sessions
		disable :run

		set :environment, :development
		#set :environment, :production

		set :static, true
		set :public, File.expand_path( File.dirname(__FILE__) + '/../static' )
		set :views, File.expand_path( File.dirname(__FILE__) + '/../views' )

		mime_type :ttf, "application/octet-stream"
		mime_type :eot, "application/octet-stream"
		mime_type :otf, "application/octet-stream"
		mime_type :woff, "application/octet-stream"


		configure :development do |c|
			require "sinatra/reloader"
			register Sinatra::Reloader
			c.also_reload "*.rb"
		end

		configure do

			config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH

			set :config, config
			set :manager, Manager.new(config)
			DataMapper.setup(:default, config.database_cfg.get_hash)


			# raise exception on save failure (globally across all models)
			DataMapper::Model.raise_on_save_failure = true

			DataMapper.auto_upgrade!
		end




		#
		#
		#
		get '/' do
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
			json = settings.manager.join params['user_id'],
				params['user_session'],
				params['user_name']

			pp json
			return json
		end


		#
		# notify server about the intention of leaving the session
		# return null user_id for confirmation
		#
		get '/api/session/leave' do
			session['user_id'] = nil
			JSON.generate({ :user_id => session['user_id'] })
		end


		#
		# Get latest patches from server
		# (update current lease)
		#
		# clients having not renewed their lease before 300
		# seconds are considered disconnected
		#
		post '/api/session/update' do
			# FIXME: verify session expiration..
			# FIXME: update session liveness

			pp JSON.parse(request.body.read) 
			JSON.generate({ :patches => [] })
		end


		#
		# Send message to the chat
		#
		put '/api/chat/post' do
			# FIXME: verify session expiration..
			# FIXME: update session liveness

			# FIXME: handle received messages
		end


		#
		# Get latest messages from chat
		#
		get '/api/chat/update' do
			# FIXME: send staging messages to clients
		end

	end
end

# un moyen d'envoyer un paquet de données
#
# recevoir le dernier paquet de données depuis la date X
#

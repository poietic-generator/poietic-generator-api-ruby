
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
		end

		configure do

			config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH

			set :config, config
			set :manager, Manager.new(config)

			#DataMapper.setup(:default, "sqlite3::memory:")
			#DataMapper.setup(:default, "sqlite3::memory:")
			DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/poietic-gen.sqlite3")

			# raise exception on save failure (globally across all models)
			DataMapper::Model.raise_on_save_failure = true

			# FIXME: make database configurable
=begin
			DataMapper.setup(:default, {
				:adapter  => 'mysql',
				:host     => 'localhost',
				:username => 'root' ,
				:password => '',
				:database => 'sinatra_development'})  
=end
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
			user = settings.manager.join params['user_id'], 
				params['user_session'],
				params['user_name']

			pp user
			# FIXME: test request user_id
			# FIXME: test request username
			# FIXME: validate session
			# FIXME: return same user_id if session is still valid

			# return JSON for userid
			# FIXME: drawing_width & drawing_height MUST depend on the configuration
			JSON.generate({ :user_id => user.id,
						 	:user_session => user.session,
						  	:user_name => user.name,
		   					:zone_column_count => 20,
							:zone_line_count => 20
			})
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
		get '/api/drawing/update' do
			JSON.generate({ :patches => [] })
		end

		#
		# Post client's latest patches
		# (update current lease)
		#
		post '/api/drawing/post' do
			# FIXME: handle received patches
		end


		# 
		# Send message to the chat
		#
		put '/api/chat/post' do
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

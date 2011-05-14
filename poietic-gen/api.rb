
require 'sinatra/base'
require "sinatra/reloader"
#require 'datamapper'

require 'poietic-gen/page'
require 'poietic-gen/manager'

require 'json'
require 'pp'

# FIXME:
# lancer un timer qui nettoie les participants déconnectés
# toutes les 300 secondes

module PoieticGen


	class Api < Sinatra::Base

		enable :sessions
		disable :run

		set :static, true
		set :public, File.expand_path( File.dirname(__FILE__) + '/../static' )
		set :views, File.expand_path( File.dirname(__FILE__) + '/../views' )

		mime_type :ttf, "application/octet-stream"
		mime_type :eot, "application/octet-stream"
		mime_type :otf, "application/octet-stream"
		mime_type :woff, "application/octet-stream"

		# DataMapper.setup(:default, "sqlite3::memory:")
		
		configure do
			set :manager, Manager.new
		end

		configure :development do |c|
			register Sinatra::Reloader
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
			pp self
			session['user_id'] = settings.manager.join

			# return JSON for userid

			JSON.generate({ :user_id => session['user_id'] })
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
		end

		#
		# Post client's latest patches
		# (update current lease)
		#
		post '/api/drawing/post' do

		end


		# 
		# Send message to the chat
		#
		put '/api/chat/post' do
			#
		end

		# 
		# Get latest messages from chat
		#
		get '/api/chat/list' do 
			#
		end

	end
end

# un moyen d'envoyer un paquet de données
#
# recevoir le dernier paquet de données depuis la date X
# 

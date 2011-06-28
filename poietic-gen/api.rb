##############################################################################
#                                                                            #
#  Poetic Generator Reloaded is a multiplayer and collaborative art          #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011 - Gnuside                                              #
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


require 'poietic-gen/config_manager'
require 'poietic-gen/page'
require 'poietic-gen/manager'

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

		enable :sessions, :run
		# set :session_secret, "FIXME: this should be removed :)"
		#disable :run

		#set :environment, :development
		set :environment, :production

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
				STDERR.puts "API -- validate_session: %s" % session.inspect
				unless session.include? SESSION_USER and
					not session[SESSION_USER].nil? then
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
			DataMapper::Logger.new(STDERR, :info)
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


		get '/page/logout' do
			settings.manager.leave session
			response.set_cookie('user_id', nil);
			response.set_cookie('user_session', nil);
			redirect '/'
		end


		#
		# notify server about the intention of joining the session
		#
		get '/api/session/join' do
			begin
				result = {}
				result = settings.manager.join session, params

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				Process.exit! #FIXME: remove in prod mode ? :-)

			ensure
				return JSON.generate( result )
			end
		end


		#
		# notify server about the intention of leaving the session
		# return null user_id for confirmation
		#
		get '/api/session/leave' do
			begin
				validate_session! session
				status = [ STATUS_SUCCESS ]

				session[SESSION_USER] = nil

			rescue InvalidSession => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_REDIRECTION ]

			rescue Exception => e
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_SERVER_ERROR ]
				Process.exit! #FIXME: remove in prod mode

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
				result = {}
				# verify session expiration..
				validate_session! session
				status = [ STATUS_SUCCESS ]

				# FIXME: extract patches information
				if settings.manager.update_lease! session then

					# FIXME: extract chat information

					data = JSON.parse(request.body.read)
					result = settings.manager.update_data session, data

				else
					status = [ STATUS_REDIRECTION, "Session has expired !", "/"]
				end

			rescue JSON::ParserError => e
				# handle non-JSON parsing errors
				STDERR.puts e.inspect, e.backtrace
				status = [ STATUS_BAD_REQUEST, "Invalid content : JSON expected" ]

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

	end
end


# -*- coding: utf-8 -*-

module PoieticGen
  module SessionsRoutes 
    def self.registered(app)
      get('/') { SessionsController.instance(app).index }
      post('/') { SessionsController.instance(app).create }
    end
  end

  class SessionsController < ApplicationController
    def index 
      @sessions = Board.all(
        closed: false,
        order: [:id.asc]
      ) || []

      @app.json({ sessions: @sessions.map(&:to_h) })
    end
    
    #
    # Create a new session
    #
    def create_route
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

		def create_session params
			is_admin = admin? params
      if not is_admin then
			  raise AdminSessionNeeded, 
			    "You have not the right to do that, please login as admin." 
      end
			
			# Create board with the configuration
			group = BoardGroup.create @config.board, params['session_name']
			return group
		end


    #
    # notify server about the intention of joining the session
    #
    def join_route
    # get '/spaces/:session_token' do
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


		def leave user_token, session_token
		  User.transaction do #NC:SMALL
			  user = User.first(token: user_token)

			  unless user.nil? then
				  board = user.board

				  user.set_expired
				  # create leave event if session is the current one
				  board.leave user
				  user.save
			  else
				  raise InvalidSession, "Cannont find any user for this request (user_token=%s)" % user_token
			  end
			end
		end

		#
		# generates an unpredictible user id based on session id & user counter
		#
		# TODO: prevent session from being stolen
		def join params
			req = JoinRequest.parse params
			result = {}

			user = nil
			now = Time.now
			param_name = User.canonical_username req.user_name

			User.transaction do |t| begin
				group = BoardGroup.from_token req.session_token
				raise InvalidSession, "Invalid session" if group.nil?

				board = group.create_board @config.board
				raise InvalidSession, "Invalid session" if board.nil?

				user = User.from_token @config.user, req.user_token, param_name, board

				# Create a zone if the user is new, or join if already exist
				if req.user_token != user.token then
					zone = board.join user, @config.board
				else
					# update expiration time
					user.idle_expires_at = now + @config.user.idle_timeout
					user.alive_expires_at = now + @config.user.liveness_timeout
					# STDERR.puts "Set expiring times at %s" % user.alive_expires_at.to_s

					# reset name if requested
					user.name = param_name
					zone = user.zone
				end

				user.save

				# get real users
				users_db = board.users.all(
					did_expire: false,
					:id.not => user.id
				)

				other_users = users_db.map{ |u| u.to_hash }
				other_zones = users_db.map{ |u| u.zone.to_desc_hash Zone::DESCRIPTION_FULL }

				msg_history_req = Message.all(user_dst: user.id) + Message.all(user_src: user.id)
				msg_history = msg_history_req.map{ |msg| msg.to_hash }

				result = {
					user_token: user.token,
					user_id: user.id, # FIXME: redundant information
					user_name: user.name,
					user_zone: (zone.to_desc_hash Zone::DESCRIPTION_FULL),
					other_users: other_users,
					other_zones: other_zones,
					zone_column_count: @config.board.width,
					zone_line_count: @config.board.height,
					timeline_id: (Timeline.last_id board),
					msg_history: msg_history
				}

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Manager.join"

				rescue Exception => e
					t.rollback
					raise e
				end
			end

			return result
		end


    #
    # Get latest patches from server
    # (update current lease)
    #
    # clients having not renewed their lease before 300
    # seconds are considered disconnected
    #
    # FIXME: add precision about updated object...
    # post '/spaces/:session_token/draw' do
    def draw
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
    def snapshot
    # get '/session/:session_token/snapshot' do
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
    def update
    # get '/session/:session_token/view/update.json' do
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

#     get '/session/:session_token/logout/:user_token' do
#       settings.manager.leave params['user_token'], params['session_token']
#       response.set_cookie('user_id', {:value => nil, :path => "/"});
#       redirect '/'
#     end
# 
# 
#     get '/session/admin' do 
#       if params[:admin_token].nil? then
#         params[:admin_token] = cookies[:admin_token] # prevent session from being lost
#       end
# 
#       if settings.manager.admin? params then
#         # @page = Page.new "admin"
#         # haml :session_admin
#       else
#         # redirect '/user/login'
#       end
#     end
  end
end


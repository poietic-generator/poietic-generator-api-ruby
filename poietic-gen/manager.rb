
require 'poietic-gen/board'
require 'poietic-gen/palette'
require 'poietic-gen/user'
require 'poietic-gen/event'
require 'poietic-gen/chat_manager'
require 'poietic-gen/message'
require 'poietic-gen/stroke'
require 'poietic-gen/update_request'

require 'pp'

module PoieticGen

	#
	# manage a pool of users
	#
	class Manager

		def initialize config
			@config = config
			pp config
			# a 16-char long random string
			@session_id = (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

			# @palette = Palette.new

			# total count of users seen (FIXME: get it from db)
			@users_seen = 0

			# Create board with the configuration
			@board = Board.new config.board

			@chat = PoieticGen::ChatManager.new config.chat

			# FIXME put it in db
			# FIXME : create session in database
		end


		#
		# generates an unpredictible user id based on session id & user counter
		#
		def join session, params
			req_id = params[:user_id]
			req_session = params[:user_session]
			req_name = params[:user_name]


			# FIXME: prevent session from being stolen...
			STDERR.puts "requesting id=%s, session=%s, name=%s" \
				% [ req_id, req_session, req_name ]

			user = nil
			now = DateTime.now
			param_request = {
				:id => req_id,
				:session => @session_id
			}
			param_create = {
				:session => @session_id,
				:name => ( req_name || 'anonymous' ),
				:zone => -1,
				:created_at => now,
				:expires_at => (now + Rational(@config.user.max_idle, 60 * 60 * 24 ))
			}

			if req_session != @session_id then
				STDERR.puts "User is requesting a different session"
				# create new
				user = User.create param_create

				# allocate new zone
				@board.join user

			else
				STDERR.puts "User is in session"
				user = User.first_or_create param_request, param_create

				if ( (now - user.expires_at) > 0  ) then
					STDERR.puts "User session expired"
					# create new if session expired
					user = User.create param_create

					@board.join user
				end
			end

			# update expiration time
			user.expires_at = (now + Rational(@config.user.max_idle, 60 * 60 * 24 ))

			user.save
			pp user
			session[PoieticGen::Api::SESSION_USER] = user.id

			# FIXME: send matrix status of user zone
			zone = @board[user.zone]

			# FIXME: test request user_id
			# FIXME: test request username
			# FIXME: validate session
			# FIXME: return same user_id if session is still valid

			# return JSON for userid
			event = Event.create_join user.id, user.zone
			event_max = Event.first(:order => [ :id.desc ])
			drawing_max = Stroke.first(:order => [ :id.desc ])
			message_max = Message.first(:order => [ :id.desc ])

			# return users & zones
			users_db = User.all( :expires_at.gt => now )
			other_users = users_db.map{ |u| u.to_hash }
			other_zones = users_db.map{ |u| @board[u.zone].to_desc_hash }

			# FIXME: send "leave event" to everyone
			return { :user_id => user.id,
				:user_session => user.session,
				:user_name => user.name,
				:user_zone => user.zone,
				:other_users => other_users,
				:other_zones => other_zones,
				:zone_column_count => @config.board.width,
				:zone_line_count => @config.board.height,
				:zone_content => zone.to_patches_hash,
				:event_id => (event_max.id || -1 ),
				:stroke_id => 0,
				:view_id => (drawing_max.id || -1 ),
				:message_id => (message_max.id || -1 )
			}
		end


		def leave session
			# FIXME: send "leave event" to everyone
			# zone_idx = @users[user_id].zone

			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER],
				:session => session[PoieticGen::Api::SESSION_SESSION]
			}
			user = User.first param_request
			if user then
				@board.leave user
			end

		end


		#
		# if not expired, update lease
		#
		# no result expected
		#
		def update_lease! session
			now = DateTime.now

			# FIXME: use configuration instead of constant
			next_expires_at = (now + Rational(@config.user.max_idle, 60 * 60 * 24 ))
			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER],
				:session => @session_id
			}
			user = User.first param_request
			raise RuntimeError, "No user found with session_id %s in DB" % @session_id if user.nil?

			if ( (now - user.expires_at) > 0  ) then
				# expired lease...
				STDERR.puts "User session expired"
				raise RuntimeError, "expired lease"
			else
				STDERR.puts "Updated lease for %s" % param_request
				user.expires_at = next_expires_at
				user.save
			end
		end


		#
		# get latest updates from user
		#
		# return latest updates from everyone !
		#
		def update_data session, data

			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER],
				:session => @session_id
			}
			user = User.first param_request

			#STDERR.puts "user:"
			#pp user
			#pp zone

			STDERR.puts "data:"
			pp data

			req = UpdateRequest.parse data

			@board.update_data user, req.drawing
			@chat.update_data user, req.chat

			# FIXME: include new drawings (excepted from this user) in response
			STDERR.puts "drawings: (since %s)" % req.strokes_since
			strokes = Stroke.all( :id.gt => req.strokes_since )
			since_stroke = strokes.map{ |d| d.to_hash }
			pp since_stroke

			STDERR.puts "events: (since %s)" % req.events_since
			events = Event.all( :id.gt => req.events_since )
			since_events = events.map{ |e| e.to_hash }
			pp since_events

			# FIXME: implement Message class first
			STDERR.puts "chat: (since %s)" % req.messages_since
			messages = Message.all(
			  :id.gt => req.messages_since,
			  :user_dst => user.id
			)
			since_messages = messages.map{ |e| e.to_hash }
			pp since_messages

			result = {
				:events => since_events,
				:strokes => since_stroke,
				:messages => since_messages,
			}

			return result
		end

	end
end

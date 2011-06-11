
require 'poietic-gen/board'
require 'poietic-gen/palette'
require 'poietic-gen/user'
require 'poietic-gen/event'
require 'poietic-gen/chat_manager'
require 'poietic-gen/message'
require 'poietic-gen/stroke'
require 'poietic-gen/update_request'
require 'thread'

require 'pp'

module PoieticGen

	#
	# manage a pool of users
	#
	class Manager

		# This constant is the one used to check the leaved user, and generate
		# events. This check is made in the update_data method. It will be done
		# at min every LEAVE_CHECK_TIME_MIN days at a user update_data request.
		LEAVE_CHECK_TIME_MIN = Rational(1,60*60*24)

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

			@last_leave_check_time = DateTime.now - LEAVE_CHECK_TIME_MIN
			@leave_mutex = Mutex.new

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
				:name => ( req_name || 'anonymous'),
				:zone => -1,
				:created_at => now,
				:expires_at => (now + Rational(@config.user.max_idle, 60 * 60 * 24 )),
				:did_expire => false
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
					# The event will be generated elsewhere (in update_data).
					STDERR.puts "User session expired"
					# create new if session expired
					user = User.create param_create

					@board.join user
				end
			end

			# kill all previous users having the same zone

			# update expiration time
			user.expires_at = (now + Rational(@config.user.max_idle, 60 * 60 * 24 ))
			user.name = req_name

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
			stroke_max = Stroke.first(:order => [ :id.desc ])
			message_max = Message.first(:order => [ :id.desc ])

			# return users & zones
			users_db = User.all(
				:expires_at.gt => now,
				:id.not => req_id
			)
			other_users = users_db.map{ |u| u.to_hash }
			other_zones = users_db.map{ |u|	@board[u.zone].to_desc_hash }

			return { :user_id => user.id,
				:user_session => user.session,
				:user_name => user.name,
				:user_zone => zone.to_desc_hash,
				:other_users => other_users,
				:other_zones => other_zones,
				:zone_column_count => @config.board.width,
				:zone_line_count => @config.board.height,
				:event_id => (event_max.id || -1 ),
				:stroke_id => (stroke_max.id || -1 ),
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

			self.check_leaved_users

			STDERR.puts "data:"
			pp data

			req = UpdateRequest.parse data

			@board.update_data user, req.drawing
			@chat.update_data user, req.chat

			# FIXME: include new drawings (excepted from this user) in response
			STDERR.puts "drawings: (since %s)" % req.strokes_since
			strokes = Stroke.all(
								 :id.gt => req.strokes_since,
								 :zone.not => user.zone
								)
			since_stroke = strokes.map{ |d| d.to_hash }
			pp since_stroke

			STDERR.puts "events: (since %s)" % req.events_since
			events = Event.all( :id.gt => req.events_since )
			since_events = events.map{ |e| e.to_hash @board }
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

		def check_leaved_users
			now = DateTime.now
			if @leave_mutex.try_lock then
				STDERR.puts "Should check leavers : %s + %s < %s" % [
					@last_leave_check_time.to_s,
					LEAVE_CHECK_TIME_MIN.to_s,
					now.to_s
				]
				if (@last_leave_check_time + LEAVE_CHECK_TIME_MIN) < now then
					STDERR.puts "++++++ Expired users"
					# Get the user which has not be already declared as
					newly_expired_users = User.all(
						:did_expire => false,
						:expires_at.lte => now
					)
					pp newly_expired_users
					newly_expired_users.each do |leaver|
						STDERR.puts " User-%d is now marked as expired." % leaver.id
						leaver.did_expire = true
						leaver.save
						Event.create_leave leaver.id, leaver.expires_at
					end
					STDERR.puts "------ Expired users"
					@last_leave_check_time = now
				end
				@leave_mutex.unlock
			else
				STDERR.puts "Leaver updates : Can't update because someone is already working on that"
			end
		end

	end
end

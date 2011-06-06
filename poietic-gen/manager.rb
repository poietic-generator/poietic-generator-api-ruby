
require 'poietic-gen/palette'
require 'poietic-gen/user'
require 'poietic-gen/event'
require 'poietic-gen/drawing_patch'
require 'poietic-gen/board'

require 'pp'

module PoieticGen


	UPDATEREQ_EVENT_SINCE = 'event_since'

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
			@board = Board.new config.board

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
				user.zone = (@board.allocate user).index

			else
				STDERR.puts "User is in session"
				user = User.first_or_create param_request, param_create

				if ( (now - user.expires_at) > 0  ) then
					STDERR.puts "User session expired"
					# create new if session expired
					user = User.create param_create
					# allocate new zone
					user.zone = (@board.allocate user).index
				end
			end

			# update expiration time
			# FIXME: use configuration instead of constant
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
			drawing_max = DrawingPatch.first(:order => [ :id.desc ])

			# FIXME: send "leave event" to everyone
			# FIXME: send zone content to user
			return { :user_id => user.id,
				:user_session => user.session,
				:user_name => user.name,
				:user_zone => user.zone,
				:zone_column_count => @config.board.width,
				:zone_line_count => @config.board.height,
				:zone_content => zone.to_patches,
				:event_id => (event_max.id || -1 ),
				:drawing_id => 0,
				:view_id => (drawing_max.id || -1 ),
				:chat_id => (event_max.id || -1 ) # FIXME: use chat_max instead of event_max
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
				self.zone_free user.id
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
			zone = @board[user.zone]

			#STDERR.puts "user:"
			#pp user
			#pp zone

			STDERR.puts "data:"
			pp data

			# validate user input first
			[ :drawing_since, :drawing, 
				:event_since, :chat, :chat_since
			].each do |sym|
				raise ArgumentError, 
					("The '%s' field is missing" % sym) unless data.include? sym.to_s
			end

			# apply drawing to zone
			zone.apply data['drawing']

			# FIXME: include new drawings (excepted from this user) in response
			since_drawing = []


			# FIXME: validate event_since as a uint
			STDERR.puts "events: (since %s)" % data[UPDATEREQ_EVENT_SINCE]
			events = Event.all( :id.gt => data[UPDATEREQ_EVENT_SINCE].to_i )
			since_events = events.map{ |e| e.to_hash }
			pp since_events

			result = {
				:event => since_events,
				:drawing => since_drawing,
				:chat => [],
			}

			return result
		end

		#
		# Relocate user offset
		def draw user_id, change

		end
	end
end

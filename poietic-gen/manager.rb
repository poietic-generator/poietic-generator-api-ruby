
require 'poietic-gen/palette'
require 'poietic-gen/database'

require 'pp'

module PoieticGen


	# FIXME: since could have the following format { ev: id, patch: id, chat: id }


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

			# FIXME put it in db
			@event_queue = []
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
				:expires_at => (now + Rational(User::MAX_IDLE, 60 * 60 * 24 ))
			}

			if req_session != @session_id then
				STDERR.puts "User is requesting a different session"
				# create new
				user = User.create param_create
				# FIXME: allocate new zone

			else
				STDERR.puts "User is in session"
				user = User.first_or_create param_request, param_create

				if ( (now - user.expires_at) > 0  ) then
					STDERR.puts "User session expired"
					# create new if session expired
					user = User.create param_create
					# FIXME: allocate new zone
				end
			end

			# update expiration time
			# FIXME: use configuration instead of constant
			user.expires_at = (now + Rational(User::MAX_IDLE, 60 * 60 * 24 ))

			# FIXME: user.zone = @board.allocate
			if user.zone < 0 then 
				STDERR.puts "no zone allocated !"
			end
			user.save
			session[:user] = user.id

			# FIXME: send matrix status of user zone

			# FIXME: test request user_id
			# FIXME: test request username
			# FIXME: validate session
			# FIXME: return same user_id if session is still valid

			# return JSON for userid

			# FIXME: send "leave event" to everyone
			# FIXME: send zone content to user
			return JSON.generate({ :user_id => user.id,
						 	:user_session => user.session,
						  	:user_name => user.name,
							:user_zone => user.zone,
		   					:zone_column_count => @config.board.width,
							:zone_line_count => @config.board.height,
							:zone_content => []
			})
		end


		def leave session
			# FIXME: send "leave event" to everyone
			# zone_idx = @users[user_id].zone

			param_request = {
			   	:id => session[:user_id],
				:session => session[:user_session]
			}
			user = User.first param_request
			if user then
				self.zone_free user.id
			end
		end


		#
		# if not expired, update lease
		#
		def update_lease session
			now = DateTime.now
			
			# FIXME: use configuration instead of constant
			next_expires_at = (now + Rational(User::MAX_IDLE, 60 * 60 * 24 ))
			param_request = {
			   	:id => session[PoieticGen::Api::SESSION_USER],
				:session => @session_id
			}
			user = User.first param_request
			raise RuntimeError if user.nil?

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

		
		# post
		#  * <user-id> changes
		#
		# returns
		#  * latest content since last update
		def sync user_id
			#
			#draw user

			return
		end

		#
		# Relocate user offset
		def draw user_id, change

		end
	end
end

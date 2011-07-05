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

require 'thread'
require 'time'
require 'pp'

require 'poietic-gen/board'
require 'poietic-gen/palette'
require 'poietic-gen/user'
require 'poietic-gen/event'
require 'poietic-gen/chat_manager'
require 'poietic-gen/message'
require 'poietic-gen/stroke'
require 'poietic-gen/update_request'
require 'poietic-gen/snapshot_request'
require 'poietic-gen/play_request'

module PoieticGen

	#
	# manage a pool of users
	#
	class Manager

		# This constant is the one used to check the leaved user, and generate
		# events. This check is made in the update_data method. It will be done
		# at min every LEAVE_CHECK_TIME_MIN days at a user update_data request.
		LEAVE_CHECK_TIME_MIN = 1

		def initialize config
			@config = config
			@debug = true
			pp config
			# a 16-char long random string
			@session_id = (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
			@session_start = Time.now.to_i

			# @palette = Palette.new

			# total count of users seen (FIXME: get it from db)
			@users_seen = 0

			# Create board with the configuration
			@board = Board.new config.board

			@chat = PoieticGen::ChatManager.new config.chat

			@last_leave_check_time = Time.now.to_i - LEAVE_CHECK_TIME_MIN
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

			is_new = true;


			# FIXME: prevent session from being stolen...
			rdebug "requesting id=%s, session=%s, name=%s" \
				% [ req_id, req_session, req_name ]

			user = nil
			now = Time.now
			param_request = {
				:id => req_id,
				:session => @session_id
			}
			param_name = if req_name.nil? or (req_name.length == 0) then
							 "anonymous"
						 else
							 req_name
						 end
			param_create = {
				:session => @session_id,
				:name => param_name,
				:zone => -1,
				:created_at => now.to_i,
				:expires_at => (now + @config.user.max_idle).to_i,
				:did_expire => false
			}

			if req_session != @session_id then
				rdebug "User is requesting a different session"
				# create new
				user = User.create param_create

				# allocate new zone
				@board.join user

			else
				rdebug "User is in session"
				user = User.first_or_create param_request, param_create

				tdiff = (now.to_i - user.expires_at)
				require 'pp'
				pp [ now.to_i, user.expires_at, tdiff ]
				if ( tdiff > 0  ) then
					# The event will be generated elsewhere (in update_data).
					rdebug "User session expired"
					# create new if session expired
					user = User.create param_create

					@board.join user
					is_new = false;
				end
			end

			# kill all previous users having the same zone

			# update expiration time
			user.expires_at = (now + @config.user.max_idle)
			rdebug "Set expiring at %s" % user.expires_at.to_s
			# reset name if requested
			user.name = param_name

			begin
				user.save
			rescue DataMapper::SaveFailureError => e
				STDERR.puts e.resource.errors.inspect
				raise e
			end
			pp user
			session[PoieticGen::Api::SESSION_USER] = user.id

			# FIXME: send matrix status of user zone
			zone = @board[user.zone]

			# FIXME: test request user_id
			# FIXME: test request username
			# FIXME: validate session
			# FIXME: return same user_id if session is still valid

			# return JSON for userid
			if is_new then
				event = Event.create_join user.id, user.zone
			end
			event_max = begin
							e = Event.first(:order => [ :id.desc ])
							if e.nil? then 0
							else e.id
							end
						end
			stroke_max = begin
							 s = Stroke.first(:order => [ :id.desc ])
							 if s.nil? then 0
							 else s.id
							 end
						 end
			message_max = begin
							  m = Message.first(:order => [ :id.desc ])
							  if m.nil? then 0
							  else m.id
							  end
						  end

			# clean-up users first
			self.check_expired_users

			# get real users
			users_db = User.all(
				:did_expire.not => true,
				:id.not => user.id,
				:session => @session_id,
				:zone.gte => 0
			)
			other_users = users_db.map{ |u| u.to_hash }
			other_zones = users_db.map{ |u|
				puts "requesting zone for %s" % u.inspect
				@board[u.zone].to_desc_hash
			}
			msg_history_req = Message.all(:user_dst => user.id) + Message.all(:user_src => user.id)
			msg_history = msg_history_req.map{ |msg| msg.to_hash }
			rdebug "msg_history req : %s" % msg_history.inspect

			result = { :user_id => user.id,
				:user_session => user.session,
				:user_name => user.name,
				:user_zone => zone.to_desc_hash,
				:other_users => other_users,
				:other_zones => other_zones,
				:zone_column_count => @config.board.width,
				:zone_line_count => @config.board.height,
				:event_id => event_max,
				:stroke_id => stroke_max,
				:message_id => message_max,
				:msg_history => msg_history
			}

			rdebug "result : %s" % result.inspect

			return result
		end


		def leave session
			# zone_idx = @users[user_id].zone

			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER],
				:session => session[PoieticGen::Api::SESSION_SESSION]
			}
			user = User.first param_request
			if user then
				@board.leave user
				user.expires_at = Time.now.to_i
				user.did_expire = true
				# create leave event if session is the current one
				if session[PoieticGen::Api::SESSION_SESSION] == @session_id then
					Event.create_leave user.id, user.expires_at, user.zone
				end
				user.save
			else
				rdebug "Could not find any user for this request";
				pp param_request;
			end

		end


		#
		# if not expired, update lease
		#
		# no result expected
		#
		def update_lease! session
			now = Time.now.to_i

			next_expires_at = (now + @config.user.max_idle)
			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER],
				:session => @session_id
			}
			user = User.first param_request
			pp user
			raise RuntimeError, "No user found with session_id %s in DB" % @session_id if user.nil?

			if ( (now.to_i - user.expires_at) > 0  ) then
				# expired lease...
				return false
			else
				# rdebug "Updated lease for %s" % param_request
				user.expires_at = next_expires_at
				user.save
				return true
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

			self.check_expired_users

			rdebug "updating with : %s" % data.inspect
			req = UpdateRequest.parse data

			@board.update_data user, req.strokes
			@chat.update_data user, req.messages

			# rdebug "drawings: (since %s)" % req.strokes_after
			strokes = Stroke.all(
				:id.gt => req.strokes_after,
				:zone.not => user.zone
			)
			strokes_collection = strokes.map{ |d| d.to_hash }

			# rdebug "events: (since %s)" % req.events_after
			events = Event.all(
				:id.gt => req.events_after
			)
			events_collection = events.map{ |e| e.to_hash @board }

			# rdebug "chat: (since %s)" % req.messages_after
			messages = Message.all(
				:id.gt => req.messages_after,
				:user_dst => user.id
			)
			messages_collection = messages.map{ |e| e.to_hash }

			result = {
				:events => events_collection,
				:strokes => strokes_collection,
				:messages => messages_collection,
				:stamp => (Time.now.to_i - @session_start)
			}

			rdebug "returning : %s" % result.inspect

			return result
		end

		def snapshot session, params

			rdebug "call with %s" % params.inspect
			req = SnapshotRequest.parse params


			# TODO : ignore session_id because it is unknow for the viewer for now
			#raise RuntimeError, "Invalid session" if req.session != @session_id


			if req.date == -1 then
			  # get the current state
			  users_db = User.all(
				  :did_expire.not => true
			  )
			  users = users_db.map{ |u| u.to_hash }
			  zones = users_db.map{ |u| @board[u.zone].to_desc_hash }
			elsif req.date == 0 then
			  # get the beginning state.
			  users = []
			  zones = []
			else
			  raise RuntimeError, "Invalide date, other than -1 and 0 is not supported"
      end


		  # TODO : must return : snapshot params (user, zone), start_time, and
		  ### duration of the session since then.
		  result = {
				:users => users,
				:zones => zones,
				:zone_column_count => @config.board.width,
				:zone_line_count => @config.board.height,
				:start_date => @session_start,
				:duration => (Time.now.to_i - @session_start)
      }

			rdebug "returning : %s" % result.inspect

      return result
		end

		def play session, params

			rdebug "call with %s" % params.inspect
			req = PlayRequest.parse params

			raise RuntimeError, "Invalid session" if req.session != @session_id

			# request structure :
			# req.since : date from where we want the params
			# req.duration : amount of time we want.


			rdebug "req.since = %d ; req.duration = %d" % [req.since, req.duration]



			evt_req = Event.all(
			  :timestamp.gte => Time.at(req.since),
			  :timestamp.lt => Time.at(req.since + req.duration)
			)

			pp evt_req

			srk_req = Stroke.all(
			  :timestamp.gte => Time.at(req.since),
			  :timestamp.lt => Time.at(req.since + req.duration)
			)

			pp srk_req

			events_collection = evt_req.map{ |e| e.to_hash @board}
			strokes_collection = srk_req.map{ |s| s.to_hash }

			result = {
				:events => events_collection,
				:strokes => strokes_collection,
				:duration => (Time.now.to_i - @session_start)
			}

			rdebug "returning : %s" % result.inspect

			return result
		end

		def check_expired_users
			now = Time.now.to_i
			if @leave_mutex.try_lock then
				# remove users without a zone
				users_db = User.all( :did_expire.not => true )
				users_db.each do |u|
					# verify that user really has a zone in that program instance
					has_zone = @board.include? u.zone
					# disable users without a zone
					if not has_zone then
						# kill non-existant user
						rdebug "Killing user with no zone : %s" % u.inspect
						u.expires_at = now
						u.did_expire = true
						u.save
					end
				end

				# remove expired users that have not yet been declared as expired
				if (@last_leave_check_time + LEAVE_CHECK_TIME_MIN) < now then
					newly_expired_users = User.all(
						:did_expire => false,
						:expires_at.lte => now
					)
					rdebug "New expired list : %s" % newly_expired_users.inspect
					newly_expired_users.each do |leaver|
						fake_session = {}
						fake_session[PoieticGen::Api::SESSION_USER] = leaver.id
						fake_session[PoieticGen::Api::SESSION_SESSION] = leaver.session
						self.leave fake_session
					end
					@last_leave_check_time = now
				end
				@leave_mutex.unlock
			else
				rdebug "Leaver updates : Can't update because someone is already working on that"
			end
		end

	end
end

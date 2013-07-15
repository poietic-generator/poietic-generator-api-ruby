# -*- coding: utf-8 -*-
##############################################################################
#                                                                            #
#  Poietic Generator Reloaded is a multiplayer and collaborative art         #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011-2013 - Gnuside                                         #
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

require 'poieticgen/board'
require 'poieticgen/zone'
require 'poieticgen/palette'
require 'poieticgen/user'
require 'poieticgen/event'
require 'poieticgen/chat_manager'
require 'poieticgen/message'
require 'poieticgen/stroke'
require 'poieticgen/timeline'
require 'poieticgen/update_request'
require 'poieticgen/snapshot_request'
require 'poieticgen/play_request'
require 'poieticgen/session'

module PoieticGen

	class InvalidSession < RuntimeError ; end

	#
	# manage a pool of users
	#
	class Manager

		# This constant is the one used to check the leaved user, and generate
		# events. This check is made in the update_data method. It will be done
		# at least every LEAVE_CHECK_TIME_MIN days at a user update_data request.
		LEAVE_CHECK_TIME_MIN = 1

		def initialize config
			@config = config
			@debug = true
			pp config
			# a 16-char long random string

			_session_init
			# FIXME put it in db
		end


		def restart session, params
			_session_init
		end

		#
		# generates an unpredictible user id based on session id & user counter
		#
		def join session, params
			req_id = params[:user_id]
			req_session = params[:user_session]
			req_name = params[:user_name]

			is_new = true;
			result = nil


			# FIXME: prevent session from being stolen...
			pp "requesting id=%s, session=%s, name=%s" \
				% [ req_id, req_session, req_name ]

			user = nil
			now = Time.now

			param_name = if req_name.nil? or (req_name.length == 0) then
							 "anonymous"
						 else
							 req_name
						 end
			param_create = {
				:session => @session,
				:name => param_name,
				:zone => -1,
				:created_at => now.to_i,
				:alive_expires_at => (now + @config.user.liveness_timeout).to_i,
				:idle_expires_at => (now + @config.user.idle_timeout).to_i,
				:did_expire => false,
				:last_update_time => now
			}

			User.transaction do

				# reuse user_id if session is still valid
				if req_session != @session.token then
					pp "User is requesting a different session"
					# create new
					user = User.create param_create

					# allocate new zone
					@board.join user

				else
					pp "User is in session"
					param_request = {
						:id => req_id
					}
					user = @session.users.first_or_create param_request, param_create

					tdiff = (now.to_i - user.alive_expires_at)
					pp [ now.to_i, user.alive_expires_at, tdiff ]
					if ( tdiff > 0  ) then
						# The event will be generated elsewhere (in update_data).
						pp "User session expired"
						# create new if session expired
						user = User.create param_create

						@board.join user
					else
						is_new = false;
					end
				end

				# kill all previous users having the same zone

				# update expiration time
				user.idle_expires_at = (now + @config.user.idle_timeout)
				user.alive_expires_at = (now + @config.user.liveness_timeout)
				pp "Set expiring times at %s" % user.alive_expires_at.to_s

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
				session[PoieticGen::Api::SESSION_SESSION] = @session.token

				zone = @board[user.zone]

				# FIXME: test request user_id
				# FIXME: test request username

				# return JSON for userid
				if is_new then
					Event.create_join user.id, user.zone, @session
				end

				# clean-up users first
				self.check_expired_users

				# get real users
				users_db = @session.users.all(
					:did_expire.not => true,
					:id.not => user.id,
					:zone.gte => 0
				)
				other_users = users_db.map{ |u| u.to_hash }
				other_zones = users_db.map{ |u|
					puts "requesting zone for %s" % u.inspect
					@board[u.zone].to_desc_hash Zone::DESCRIPTION_FULL
				}
				msg_history_req = Message.all(:user_dst => user.id) + Message.all(:user_src => user.id)
				msg_history = msg_history_req.map{ |msg| msg.to_hash }
				pp "msg_history req : %s" % msg_history.inspect


				result = { :user_id => user.id,
					:user_session => user.session.token,
					:user_name => user.name,
					:user_zone => (zone.to_desc_hash Zone::DESCRIPTION_FULL),
					:other_users => other_users,
					:other_zones => other_zones,
					:zone_column_count => @config.board.width,
					:zone_line_count => @config.board.height,
					:timeline_id => Timeline.last_id,
					:msg_history => msg_history
				}
			end

			rdebug "result : %s" % result.inspect
			pp result

			return result
		end


		def leave session
			pp "FIXME: LEAVE(session)", session
			# zone_idx = @users[user_id].zone

			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER]
			}
			pp "FIXME: LEAVE(param_request)", param_request

			cur_session = Session.first( :token => session[PoieticGen::Api::SESSION_SESSION] )
			if cur_session then
				user = cur_session.users.first param_request
				pp "FIXME: LEAVE(user)", user
			end

			if user then
				user.idle_expires_at = Time.now.to_i
				user.alive_expires_at = Time.now.to_i
				user.did_expire = true
				# create leave event if session is the current one
				if session[PoieticGen::Api::SESSION_SESSION] == @session.token then
					@board.leave user
					Event.create_leave user.id, user.alive_expires_at, user.zone, @session
				end
				user.save
			else
				rdebug "Could not find any user for this request (user=%s)" % param_request.inspect;
				pp param_request;
			end

		end


		#
		# if not expired, update lease
		#
		# no result expected
		#
		def check_lease! session
			now = Time.now.to_i

			param_request = {
				:id => session[PoieticGen::Api::SESSION_USER]
			}
			user = @session.users.first param_request
			pp user, now
			raise InvalidSession, "No user found with session %d in DB" % @session.id if user.nil?

			if ( (now >= user.alive_expires_at) or (now >= user.idle_expires_at) ) then
				# expired lease...
				return false
			else
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
				:id => session[PoieticGen::Api::SESSION_USER]
			}

			# parse update request first
			rdebug "updating with : %s" % data.inspect
			req = UpdateRequest.parse data

			# prepare empty result message
			result = nil

			User.transaction do

				user = @session.users.first param_request
				now = Time.now.to_i

				self.check_expired_users


				user.alive_expires_at = (now + @config.user.liveness_timeout)
				if not req.strokes.empty? then
					user.idle_expires_at = (now + @config.user.idle_timeout)
				end
				user.save

				@board.update_data user, req.strokes
				@chat.update_data user, req.messages
				
				timelines = @session.timelines.all(
					:id.gt => req.timeline_after
				)

				# rdebug "drawings: (since %s)" % req.timeline_after
				strokes = timelines.strokes.all(
					:zone.not => user.zone
				)
				
				ref_stamp = user.last_update_time - req.update_interval

				strokes_collection = strokes.map{ |d| d.to_hash ref_stamp }

				# rdebug "events: (since %s)" % req.timeline_after
				events = timelines.events
				events_collection = events.map{ |e| e.to_hash @board[e.zone_index], ref_stamp }

				# rdebug "chat: (since %s)" % req.timeline_after
				messages = timelines.messages.all(
					:user_dst => user.id
				)
				messages_collection = messages.map{ |e| e.to_hash }

				user.last_update_time = now
				# FIXME: handle the save
				user.save

				result = {
					:events => events_collection,
					:strokes => strokes_collection,
					:messages => messages_collection,
					:stamp => (now - @session.timestamp), # FIXME: unused by the client
					:idle_timeout => (user.idle_expires_at - now)
				}

				rdebug "returning : %s" % result.inspect

			end
			return result
		end


		#
		# Return a session snapshot
		#
		def snapshot session, params

			rdebug "call with %s" % params.inspect
			req = SnapshotRequest.parse params
			result = nil

			User.transaction do

				self.check_expired_users

				# ignore session_id from the viewer point of view but use server one
				# to distinguish old sessions/old users

				now_i = Time.now.to_i - 1
				date_range = -1
				
				# we take a snapshot one second in the past to be sure we will get
				# a complete second.
				if req.date == -1 then
					# get the current state, select only this session
					users_db = @session.users.all(
						:did_expire.not => true
					)
					users = users_db.map{ |u| u.to_hash }
					zones = users_db.map{ |u| @board[u.zone].to_desc_hash Zone::DESCRIPTION_FULL }
					
					timeline_id = Timeline.last_id
					diffstamp = 0
				else
					# retrieve the total duration of the game

					first_timeline = Timeline.first(:order => [ :id.asc ])
					pp first_timeline
					date_range = if first_timeline.nil? then 0 else (now_i - first_timeline.timestamp) end

					# retrieve stroke_max and event_max

					if req.date == 0 then
						# get the first state.

						timeline_id = if first_timeline.nil? then 0 else first_timeline.id end
						diffstamp = 0
					else
						if req.date > 0 then
							# get the state from the beginning.

							absolute_time = if first_timeline.nil? then 0
								else (first_timeline.timestamp + req.date) end
						else
							# get the state from now.

							absolute_time = now_i + req.date + 1
						end

						STDOUT.puts "abs_time %d (now %d, date %d)" % [absolute_time, now_i, req.date]

						t = Timeline.first(
							:timestamp.lte => absolute_time,
							:order => [ :id.desc ]
						)

						timeline_id = if t.nil? then 0 else t.id end
						diffstamp = if t.nil? then 0 else absolute_time - t.timestamp end
					end

					STDOUT.puts "timeline_id %d" % timeline_id

					# retrieve users and zones
					
					users, zones = @board.load_board timeline_id
					
					zones = zones.map{ |i,z| z.to_desc_hash Zone::DESCRIPTION_FULL }
				end

				# return snapshot params (user, zone), start_time, and
				# duration of the session since then.
				result = {
					:users => users, # TODO: unused by the viewer
					:zones => zones,
					:zone_column_count => @config.board.width,
					:zone_line_count => @config.board.height,
					:timeline_id => timeline_id,
					:date_range => date_range,
					:diffstamp => diffstamp, # time between the found timeline and the requested date
					:id => req.id
				}

				rdebug "returning : %s" % result.inspect

			end
			return result
		end

		#
		# Get strokes and events for a non-user viewer.
		#
		def play session, params

			rdebug "call with %s" % params.inspect
			req = PlayRequest.parse params
			now_i = Time.now.to_i
			result = nil

			# TODO : ignore session_id because it is unknow for the viewer for now
			#raise RuntimeError, "Invalid session" if req.session != @session.id

			Event.transaction do

				self.check_expired_users

				rdebug "req.timeline_after = %d" % req.timeline_after

				# Get events and strokes between req.timeline_after and req.duration

				strokes_collection = []
				events_collection = []
				timestamp = 0

				if req.view_mode == PlayRequest::REAL_TIME_VIEW then
					timelines = Timeline.all(
						:id.gt => req.timeline_after
					)	
				
					evt_req = timelines.events

					pp evt_req
					
					srk_req = timelines.strokes

					pp srk_req
					
					first_timeline = timelines.first(
						:order => [ :id.asc ]
					)
					
					events_collection = evt_req.map{ |e|
						e.to_hash @board[e.zone_index], first_timeline.timestamp
					}
				
					strokes_collection = srk_req.map{ |s|
						s.to_hash first_timeline.timestamp
					}
					
				elsif req.view_mode == PlayRequest::HISTORY_VIEW then
					
					STDOUT.puts "HISTORY_VIEW"
					
					# This stroke is used to compute diffstamps
					since = Timeline.get(req.since);
					
					if not since.nil? then
					
						first_t = Timeline.first(
							:id.gt => req.timeline_after,
							:order => [ :id.asc ]
						)

						if first_t.nil? then
							max_timestamp = -1
							min_timestamp = -1
						else
							min_timestamp = first_t.timestamp
							max_timestamp = min_timestamp + req.duration
						
							timelines = Timeline.all(
								:id.gt => req.timeline_after,
								:timestamp.lte => max_timestamp,
								:order => [ :id.asc ]
							)
					
							srk_req = timelines.strokes

							strokes_collection = srk_req.map{ |s|
								s.to_hash since.timestamp
							}
						
							evt_req = timelines.events

							if not evt_req.empty? then
								STDOUT.puts "first timeline"
								pp first_t
						
								STDOUT.puts "Max timestamp=%d" % max_timestamp
						
								STDOUT.puts "Strokes"
								pp srk_req

								STDOUT.puts "Events"
								pp evt_req
						
								users, zones = @board.load_board timelines.last.id
								# FIXME: load_board loads some useless data for what we want
								# FIXME: zones seems to be wrong
						
								events_collection = evt_req.map{ |e| e.to_hash zones[e.zone_index], since.timestamp }
							end
						end
					
						first_timeline_ever = Timeline.first(:order => [ :id.asc ])
						timestamp = if first_timeline_ever.nil? or min_timestamp < 0
							    then 0
							    else
							    	min_timestamp - first_timeline_ever.timestamp
							    end
					end
				else
					raise RuntimeError, "Unknown view mode %d" % req.view_mode
				end

				result = {
					:events => events_collection,
					:strokes => strokes_collection,
					:timestamp => timestamp, # relative to the start of the game
					:id => req.id,
				}

				rdebug "returning : %s" % result.inspect
			end
			return result
		end


		#
		#
		#
		def check_expired_users
			User.transaction do
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
							u.idle_expires_at = now
							u.alive_expires_at = now
							u.did_expire = true
							u.save
						end
					end

					# remove expired users that have not yet been declared as expired
					if (@last_leave_check_time + LEAVE_CHECK_TIME_MIN) < now then
						newly_expired_users = User.all(
							:did_expire => false,
							:alive_expires_at.lte => now
						) + User.all(
						:did_expire => false,
						:idle_expires_at.lte => now
						)
						rdebug "New expired list : %s" % newly_expired_users.inspect
						newly_expired_users.each do |leaver|
							fake_session = {}
							fake_session[PoieticGen::Api::SESSION_USER] = leaver.id
							fake_session[PoieticGen::Api::SESSION_SESSION] = leaver.session.token
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

		private

		def _session_init 
			@session = Session.new

			# total count of users seen (FIXME: get it from db)
			@users_seen = 0

			# Create board with the configuration
			@board = Board.new @config.board
			# Take the initial snapshot of the board
			@board.save @session

			@chat = PoieticGen::ChatManager.new @config.chat

			@last_leave_check_time = Time.now.to_i - LEAVE_CHECK_TIME_MIN
			@leave_mutex = Mutex.new
		end

	end
end

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
require 'poieticgen/admin'
require 'poieticgen/event'
require 'poieticgen/chat_manager'
require 'poieticgen/message'
require 'poieticgen/stroke'
require 'poieticgen/timeline'
require 'poieticgen/update_request'
require 'poieticgen/snapshot_request'
require 'poieticgen/update_view_request'
require 'poieticgen/join_request'
require 'poieticgen/transaction'

module PoieticGen

	class InvalidSession < RuntimeError ; end
	class AdminSessionNeeded < RuntimeError ; end

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
			# @debug = true
			pp config
			# a 16-char long random string
			
			@chat = PoieticGen::ChatManager.new @config.chat

			@last_leave_check_time = Time.now.to_i - LEAVE_CHECK_TIME_MIN
			@leave_mutex = Mutex.new
		end


		def create_session params
			is_admin = admin? params
			raise AdminSessionNeeded, "You have not the right to do that, please login as admin." if not is_admin
			
			# Create board with the configuration
			group = BoardGroup.create @config.board, params['session_name']
			return group
		end

		#
		# generates an unpredictible user id based on session id & user counter
		#
		def join params
			req = JoinRequest.parse params

			is_new = true
			result = {}

			# FIXME: prevent session from being stolen...
			rdebug "requesting user_token=%s, session=%s, name=%s" \
				% [ req.user_token, req.session_token, req.user_name ]

			user = nil
			now = Time.now

			param_name = User.canonical_username req.user_name

			User.transaction do |t| begin
				# clean-up users first
				self.check_expired_users

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
					rdebug "Set expiring times at %s" % user.alive_expires_at.to_s

					# reset name if requested
					user.name = param_name
					zone = user.zone
				end

				begin
					user.save
				rescue DataMapper::SaveFailureError => e
					STDERR.puts e.resource.errors.inspect
					raise e
				end

				rdebug "User : ", user

				# get real users
				users_db = board.users.all(
					:did_expire => false,
					:id.not => user.id
				)

				other_users = users_db.map{ |u| u.to_hash }
				other_zones = users_db.map{ |u|
					rdebug "requesting zone for %s" % u.inspect
					u.zone.to_desc_hash Zone::DESCRIPTION_FULL
				}

				msg_history_req = Message.all(:user_dst => user.id) + Message.all(:user_src => user.id)
				msg_history = msg_history_req.map{ |msg| msg.to_hash }

				rdebug "msg_history req : %s" % msg_history.inspect


				result = {
					:user_token => user.token,
					:user_id => user.id, # FIXME: redundant information
					:user_name => user.name,
					:user_zone => (zone.to_desc_hash Zone::DESCRIPTION_FULL),
					:other_users => other_users,
					:other_zones => other_zones,
					:zone_column_count => @config.board.width,
					:zone_line_count => @config.board.height,
					:timeline_id => (Timeline.last_id board),
					:msg_history => msg_history
				}

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Manager.join"

				rescue Exception => e
					t.rollback
					raise e
				end
			end

			rdebug "result : %s" % result.inspect

			return result
		end
		
		def admin_join params
			req_name = params[:user_name]
			req_password = params[:user_password]

			# FIXME: prevent session from being stolen...
			rdebug "requesting name=%s" % req_name

			user = nil
			now = Time.now

			is_admin = if req_password.nil? or req_name.nil? then false
			           else req_password == @config.server.admin_password and
			                req_name == @config.server.admin_username
			           end

			raise AdminSessionNeeded, "Invalid parameters." if not is_admin

			admin = Admin.first(:name => req_name)
			
			if admin.nil? then
				admin = Admin.create req_name, @config.user
			else
				admin.report_expiration @config.user
			end

			return admin.token
		end


		def leave user_token, session_token
			rdebug "FIXME: LEAVE(user_token)", user_token
			#FIXME: use session_token?

			user = User.first(:token => user_token)

			unless user.nil? then
				board = user.board

				user.set_expired
				# create leave event if session is the current one
				board.leave user
				user.save
			else
				rdebug "Could not find any user for this request (user_token=%s)" % user_token
			end
		end


		def admin_leave params
			req_token = params[:admin_token]

			admin = Admin.first(:token => req_token)

			unless admin.nil? then
				admin.set_expired
			end
		end


		def admin? params
			req_token = params[:admin_token]

			admin = Admin.first(:token => req_token)

			return (!admin.nil? and !admin.expired?)
		end


		#
		# get latest updates from user
		#
		# return latest updates from everyone !
		#
		def update_data data

			# parse update request first
			rdebug "updating with : %s" % data.inspect

			req = UpdateRequest.parse data

			# prepare empty result message
			result = {}
			now = Time.now.to_i

			User.transaction do |t| begin

				self.check_expired_users

				user = User.first(:token => req.user_token)
				if user.nil? or user.expired? then
					raise InvalidSession, "Session has expired!"
				end

				board = user.board
				if board.nil? or
				   board.closed or
				   board.board_group.token != req.session_token then
					raise InvalidSession, "No opened session found for board %s" % req.session_token
				end

				ref_stamp = user.last_update_time - req.update_interval

				user.alive_expires_at = now + @config.user.liveness_timeout
				if not req.strokes.empty? then
					user.idle_expires_at = now + @config.user.idle_timeout
				end
				user.last_update_time = now

				user.save

				begin
					board.update_data user, req.strokes
				rescue PoieticGen::TakeSnapshotError => e
					# Ignore error
					STDERR.puts "Take snapshot error ignored!"
				end
				@chat.update_data user, req.messages
				
				timelines = board.timelines.all(
					:id.gt => req.timeline_after
				)

				# rdebug "drawings: (since %s)" % req.timeline_after
				strokes = timelines.strokes.all(
					:zone.not => user.zone
				)

				strokes_collection = strokes.map{ |d| d.to_hash ref_stamp }

				# rdebug "events: (since %s)" % req.timeline_after
				events_collection = timelines.events.map{ |e| e.to_hash ref_stamp }

				# rdebug "chat: (since %s)" % req.timeline_after
				messages = timelines.messages.all(
					:user_dst => user.id
				)
				messages_collection = messages.map{ |e| e.to_hash }

				result = {
					:events => events_collection,
					:strokes => strokes_collection,
					:messages => messages_collection,
				}

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Manager.update_data"

				rescue Exception => e
					t.rollback
					raise e
				end
			end

			rdebug "returning : %s" % result.inspect

			return result
		end


		#
		# Return a session snapshot
		#
		def snapshot params

			rdebug "call with %s" % params.inspect
			req = SnapshotRequest.parse params
			result = {}

			User.transaction do |t| begin

				self.check_expired_users


                # test if session_token is defined
                pp req.session_token

				board = Board.from_token req.session_token
				raise InvalidSession, "Invalid session" if board.nil?

				# ignore session_id from the viewer point of view but use server one
				# to distinguish old sessions/old users

				timeline_id = 0
				date_range = -1
				diffstamp = 0
				timestamp = -1
				
				# we take a snapshot one second in the past to be sure we will get
				# a complete second.
				if req.date == -1 then
					# get the current state, select only this session
					users_db = board.users.all(
						:did_expire => false
					)
					users = users_db.map{ |u| u.to_hash }
					zones = users_db.map{ |u| u.zone.to_desc_hash Zone::DESCRIPTION_FULL }
					
					timeline_id = Timeline.last_id board

					rdebug "timeline_id %d" % timeline_id
				else
					end_session = if board.end_timestamp <= 0
					              then Time.now.to_i - 1
					              else board.end_timestamp
					              end
					# retrieve the total duration of the game
					date_range = end_session - board.timestamp

					# retrieve stroke_max and event_max

					if req.date != 0 then
						if req.date > 0 then
							# get the state from the beginning.

							absolute_time = board.timestamp + req.date
						else
							# get the state from end of session.

							absolute_time = end_session + req.date + 1
						end

						rdebug "abs_time %d (end_session %d, date %d)" % [absolute_time, end_session, req.date]
						
						timestamp = absolute_time - board.timestamp

						# retrieve users and zones
						zones = board.load_board absolute_time

						users = zones.map{ |i,z| z.user.to_hash }
						zones = zones.map{ |i,z| z.to_desc_hash Zone::DESCRIPTION_FULL }
					else
						timestamp = 0
						users = zones = [] # no events => no users => no zones
					end
				end

				# return snapshot params (user, zone), start_time, and
				# duration of the session since then.
				result = {
					:users => users, # TODO: unused by the viewer
					:zones => zones,
					:zone_column_count => @config.board.width,
					:zone_line_count => @config.board.height,
					:timeline_id => timeline_id,
					:timestamp => timestamp, # time between the session start and the requested date
					:date_range => date_range, # total time of session
					:id => req.id
				}

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Manager.update_data"

				rescue Exception => e
					t.rollback
					raise e
				end
			end

			rdebug "returning : %s" % result.inspect

			return result
		end

		#
		# Get strokes and events for a non-user viewer.
		#
		def update_view params

			rdebug "call with %s" % params.inspect
			req = UpdateViewRequest.parse params
			now_i = Time.now.to_i
			result = {}

			User.transaction do |t| begin

				self.check_expired_users

                # test if session_token is defined
				board = Board.from_token req.session_token
				raise InvalidSession, "Invalid session" if board.nil?

				# Get events and strokes between req.timeline_after and req.duration

				strokes_collection = []
				events_collection = []
				timestamp = 0
				next_timeline_id = -1
				max_timestamp = -1

				if req.view_mode == UpdateViewRequest::REAL_TIME_VIEW then
					#rdebug "REAL_TIME_VIEW"
					#rdebug "req.timeline_after = %d" % req.timeline_after
				
					timelines = board.timelines.all(
						:id.gte => req.timeline_after
					)
					
					srk_req = timelines.strokes
					#rdebug srk_req
					evt_req = timelines.events
					#rdebug evt_req
					
					first_timeline = timelines.first(
						:order => [ :id.asc ]
					)
				
					strokes_collection = srk_req.map{ |s|
						s.to_hash first_timeline.timestamp
					}
					
					events_collection = evt_req.map{ |e|
						e.to_hash first_timeline.timestamp
					}

				elsif req.view_mode == UpdateViewRequest::HISTORY_VIEW then
					#rdebug "HISTORY_VIEW"
					# rdebug "req.last_max_timestamp = %d, req.since = %d, req.duration = %d" %
					#	[ req.last_max_timestamp, req.since, req.duration ]
					
					end_session = if board.end_timestamp <= 0
					              then Time.now.to_i - 1
					              else board.end_timestamp
					              end
					# retrieve the total duration of the game
					date_range = end_session - board.timestamp

					session_timelines = board.timelines
					
					if req.last_max_timestamp > 0 then
						max_timestamp = req.last_max_timestamp + req.duration * 2
						# Events between the requested timestamp and (timestamp + duration)
						timelines = session_timelines.all(
							:timestamp.gt => board.timestamp + req.last_max_timestamp,
							:timestamp.lte => board.timestamp + max_timestamp
						)
					else
						max_timestamp = req.duration * 2
						timelines = session_timelines.all(
							:timestamp.lte => board.timestamp + max_timestamp
						)
					end
					
					# rdebug "timelines = ", timelines
					
					if not timelines.empty? then

						srk_req = timelines.strokes

						strokes_collection = srk_req.map{ |s| s.to_hash (board.timestamp + req.since) }

						# rdebug "Strokes ", srk_req

						evt_req = timelines.events

						# rdebug "Events ", evt_req

						events_collection = evt_req.map{ |e| e.to_hash (board.timestamp + req.since) }

						timestamp = timelines.first.timestamp - board.timestamp
					end
				else
					raise RuntimeError, "Unknown view mode %d" % req.view_mode
				end

				result = {
					:events => events_collection,
					:strokes => strokes_collection,
					:timestamp => timestamp, # relative to the start of the game session
					:max_timestamp => max_timestamp,
					:date_range => date_range, # total time of session
					:id => req.id,
				}

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Manager.update_data"

				rescue Exception => e
					t.rollback
					raise e
				end
			end

			# rdebug "returning : %s" % result.inspect

			return result
		end


		#
		#
		#
		def check_expired_users
			now = Time.now.to_i

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
					self.leave leaver.token, leaver.board.board_group.token
				end
				@last_leave_check_time = now
			end
		end
	end
end

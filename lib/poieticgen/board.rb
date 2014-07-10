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

require 'poieticgen/update_request'
require 'poieticgen/zone'
require 'poieticgen/user'
require 'poieticgen/timeline'
require 'poieticgen/board_snapshot'
require 'poieticgen/transaction'

require 'poieticgen/allocation/spiral'
require 'poieticgen/allocation/random'

require 'monitor'

module PoieticGen

	class TakeSnapshotError < RuntimeError ; end

	#
	# A class that manages the global drawing
	#
	class Board
		include DataMapper::Resource

		property :id,            Serial
		#property :name,          String,  :unique => true, :required=> false
		property :timestamp,     Integer, :required => true
		property :end_timestamp, Integer, :default => 0
		
		property :closed,        Boolean, :default => false
		property :strokes_since_last_snapshot, Integer, :default => 0

		belongs_to :board_group
		has n, :board_snapshots
		has n, :timelines
		has n, :users
		has n, :zones

		STROKE_COUNT_BETWEEN_QFRAMES = 25 # FIXME: move in config

		attr_reader :config

		ALLOCATORS = {
			"spiral" => PoieticGen::Allocation::Spiral,
			"random" => PoieticGen::Allocation::Random,
		}


		def self.check_expired_boards
			boards = Board.all(closed: false)
			boards.each do |board|
				if board.live_users_count == 0 then
					STDERR.puts "board %d" % board.id
					board.close
				end
			end
		end

		def self.create config, group
			res = super({
				# FIXME: when the token already exists, SaveFailureError is raised
				#:token => (0...16).map{ ('a'..'z').to_a[rand(26)] }.join,
				:timestamp => Time.now.to_i,
				:board_group => group
			})

			@debug = true
			rdebug "using allocator %s" % config.allocator
			return res

		rescue DataMapper::SaveFailureError => e
			rdebug "Saving failure : %s" % e.resource.errors.inspect
			raise e
		end

		# if not, use the latest session
		def self.from_token token
			# FIXME: use a constant for latest session name
			if token == "latest" then
				Board.first(:order => [:id.desc])
			else
				id = token # FIXME
				Board.get id
			end
		end

		def token
			return self.id # FIXME
		end

		def close
			t = Board.transaction do |t|
				self.closed = true
				self.end_timestamp = Time.now.to_i

				self.save
			end

		rescue DataMapper::SaveFailureError => e
			rdebug "Saving failure : %s" % e.resource.errors.inspect
			raise e

		rescue DataObjects::TransactionError => e
			Transaction.handle_deadlock_exception e, t, "Board.close"
			raise e

		rescue Exception => e
			t.rollback
			raise e
		end


		#
		# make the user join the board
		#
		def join user, config
			zone = nil
			Board.transaction do |t|
				begin
					allocator = ALLOCATORS[self.board_group.allocator_type].new config, self.zones
					zone = allocator.allocate self
					zone.user = user
					user.zone = zone
					zone.save

					Event.create_join user, self

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Board.join"
					raise e

				rescue Exception => e
					t.rollback
					raise e
				end
			end
			return zone
		end


		#
		# disconnect user from the board
		#
		def leave user
			Board.transaction do |t|
				begin
					zone = user.zone # FIXME: verify if the user is in the board
					unless zone.nil? then
						zone.reset
						zone.disable
						zone.save

						Event.create_leave user, self
					else
						#FIXME: return an error to the user?
					end

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Board.leave"
					raise e

				rescue Exception => e
					t.rollback
					raise e
				end
			end
		end


		def update_data user, drawing
			return if drawing.empty?
		
			# Update the zone

			user.zone.apply drawing

			Board.transaction do |t|
				begin
					# Save board periodically

					stroke_count = self.strokes_since_last_snapshot + drawing.size

					if stroke_count > STROKE_COUNT_BETWEEN_QFRAMES then
						board_snap = BoardSnapshot.create self
						alive_zones = self.zones.all(:expired => false)

						# FIXME: "zone.snapshot board_snap.timeline" can return nil?
						alive_zones.each do |zone|
							board_snap.zone_snapshots << (zone.snapshot board_snap.timeline)
						end

						board_snap.save

						stroke_count = 0
					end

					self.strokes_since_last_snapshot = stroke_count
					self.save

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Board.update_data"
					raise TakeSnapshotError

				rescue Exception => e
					t.rollback
					raise e
				end
			end
		end


		#
		# Get the board state at timestamp.
		#
		def load_board timestamp

			snap = _get_snapshot timestamp
			zones = {}

			if snap.nil? then
				# no snapshot: the board is empty
				snap_timeline = 0
			else
				snap_timeline = snap.timeline.id

				# Create zones from snapshot
				snap.zone_snapshots.each do |zs|
					zones[zs.zone.index] = Zone.from_snapshot zs
				end
			end
			
			# get events since the snapshot
			timelines = self.timelines.all(
				:id.gt => snap_timeline,
				:timestamp.lte => timestamp,
				:order => [ :timestamp.asc, :id.asc ]
			)

			return apply_events timelines, zones
		end


		def apply_events timelines, zones
			# Add/Remove zones since the snapshot
			timelines.events.each do |event|
				user = event.user
				zone = user.zone
				
				if event.type == "join" then
					zone.reset
					zone.expired = false
					zones[zone.index] = zone
				elsif event.type == "leave" then
					# unallocate zone
					zone.reset
					zone.disable
					zones[zone.index] = zone
				else
					raise RuntimeError, "Unknown event type %s" % event.type
				end
			end

			strokes = timelines.strokes
			zones = zones.select{ |i,z| not z.expired }

			# Apply strokes
			zones.each do |index,zone|
				zone.apply_local strokes.select{ |s| s.zone.id == zone.id }
			end
			
			return zones
		end


		def max_size
			min_left = 0
			max_right = 0
			min_top = 0
			max_bottom = 0

			# FIXME: store zone size in board
			self.zones.each do |zone|
				x, y = zone.position
				x *= zone.width
				y *= zone.height
				min_left = x if x < min_left
				max_right = x + zone.width if x + zone.width > max_right
				min_top = y if y < min_top
				max_bottom = y + zone.height if y + zone.height > max_bottom
			end

			return (max_right - min_left), (max_bottom - min_top), min_left, min_top
		end

		def live_users_count
			return self.users.all(did_expire: false).count
		end

		def total_users_count
			return self.users.count
		end

		private

		#
		# return the snapshot preceeding timestamp
		#
		def _get_snapshot timestamp
			timeline = self.board_snapshots.timelines.first(
				:timestamp.lte => timestamp,
				:order => [ :id.desc ]
			)
			
			if timeline.nil? then
				return nil
			end

			return timeline.board_snapshot
		end

	end

end


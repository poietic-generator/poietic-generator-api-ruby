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

require 'poieticgen/allocation/spiral'
require 'poieticgen/allocation/random'

require 'monitor'

module PoieticGen

	#
	# A class that manages the global drawing
	#
	class Board

		STROKE_COUNT_BETWEEN_QFRAMES = 5

		attr_reader :config

		ALLOCATORS = {
			"spiral" => PoieticGen::Allocation::Spiral,
			"random" => PoieticGen::Allocation::Random,
		}


		def initialize config
			@debug = true
			rdebug "using allocator %s" % config.allocator
			@config = config
			@allocator = ALLOCATORS[config.allocator].new config
			pp @allocator
			@monitor = Monitor.new
			@stroke_count = 0
		end


		#
		# Get access to zone with given index
		#
		def [] idx
			return @allocator[idx]
		end

		def include? idx
			@monitor.synchronize do
				val = @allocator[idx]
				return (not val.nil?)
			end
		end


		#
		# make the user join the board
		#
		def join user
			zone = nil
			@monitor.synchronize do
				zone = @allocator.allocate
				zone.user_id = user.id
				user.zone = zone.index
				zone.save
				user.save
			end
			return zone
		end


		#
		# disconnect user from the board
		#
		def leave user
			@monitor.synchronize do
				# reset zone
				@allocator[user.zone].reset
				# unallocate it
				@allocator.free user.zone
			end
		end


		def update_data user, drawing
			return if drawing.empty?
		
			@monitor.synchronize do
				# Save board periodically
				# before the update because the first snapshot
				# must starts at stroke_id = 0
				
				if @stroke_count == 0 then
					last_stroke_id = Manager.get_timeline_id
					if SnapshotBoard.first(:stroke => last_stroke_id).nil? then
						self.save last_stroke_id, user.session
					end
				end
				
				@stroke_count = (@stroke_count + drawing.length) % STROKE_COUNT_BETWEEN_QFRAMES;

				STDOUT.puts "stroke_count %d" % [@stroke_count]
				
				# Update the zone
			
				zone = @allocator[user.zone]
				unless zone.nil? then
					zone.apply user, drawing
				else
					#FIXME: return an error to the user ?
				end
			end
		end

		def save last_stroke, session_id

			users = User.all(:session => session_id)
			zones = []

			users.each do |user|
				zones.push(@allocator[user.zone])
			end

			SnapshotBoard.new zones, last_stroke, session_id
		end
		
		#
		# Get the board state at stroke_id.
		# FIXME: load_board is not static because it depends on @config.
		#
		def load_board stroke_id
			
			if stroke_id < 0 then
				stroke_id = 0
			end
		
			# The first snap before stroke_id
			snap = SnapshotBoard.first(
				:stroke.lte => stroke_id,
				:order => [ :stroke.desc ]
			)
			
			if snap.nil? then
				# FIXME: the first snapshot isn't the first state of the game
				snap = SnapshotBoard.first(
					:order => [ :stroke.asc ]
				)
			
				if snap.nil? then
					raise RuntimeError, "No snapshot found for stroke %d" % stroke_id
				end
			end
			
			STDOUT.puts "snap"
			pp snap
			
			# get the session associated to the snapshot
			users_db = User.all(
				:session => snap.session
			)
			
			STDOUT.puts "users_db"
			pp users_db
			
			strokes_db = Stroke.all(
				:id.gt => snap.stroke,
				:id.lte => stroke_id
			)
			
			STDOUT.puts "strokes_db"
			pp strokes_db
		
			events_db = Event.all(
				:id.gt => snap.stroke,
				:id.lte => stroke_id
			)
			
			STDOUT.puts "events_db"
			pp events_db
			
			# Create zones from snapshot
			zones_snap = snap.data.map{ |d|
				Zone.from_hash d, @config.width, @config.height
			}
			
			STDOUT.puts "zones_snap"
			pp zones_snap
			
			# Put zones from snapshot in allocator
			allocator = ALLOCATORS[@config.allocator].new @config
			zone_indexes = Hash.new
			
			zones_snap.each do |zone|
				allocator.insert zone
				zone_indexes[zone.user_id] = zone.index
			end
			
			STDOUT.puts "Allocator snapshot"
			pp allocator
			pp zone_indexes
			
			# Add/Remove zones since the snapshot
			events_db.each do |event|
				zone_index = event.zone_index
				user_id = event.zone_user
				
				STDOUT.puts "%s user_id = %d, zone_index = %d" % [ event.type, user_id, zone_index ]
				if event.type == "join" then
					zone = allocator.allocate_at zone_index
					zone.user_id = user_id
					zone_indexes[user_id] = zone_index
				elsif event.type == "leave" then
					# reset zone
					allocator[zone_index].reset
					# unallocate it
					allocator.free zone_index
				else
					raise RuntimeError, "Unknown event type %s" % event.type
				end
			end
			
			STDOUT.puts "Allocator after events"
			pp allocator
			pp zone_indexes
			
			users = users_db.map{ |u| u.to_hash } # FIXME: All users in the session are returned
			strokes = strokes_db.map{ |s| s.to_hash s.timestamp } # strokes with diffstamp = 0 (not important)
			zones = []
			
			# Apply strokes
			zone_indexes.each do |user_id,zone_index|
				zone = allocator[zone_index]
				if zone.user_id != nil then
					zone.apply_local strokes.select{ |s| s["zone"] == zone.index }
				end
				zones[zone_index] = zone
			end

			STDOUT.puts "users, zones and strokes"
			pp users
			pp zones
			pp strokes
			
			return users, zones
		end
	end

end


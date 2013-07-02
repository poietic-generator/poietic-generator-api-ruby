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
					last_stroke = Stroke.first(:order => [ :id.desc ])
					last_event = Event.first(:order => [ :id.desc ])
					if not last_stroke.nil? and not last_event.nil? then
						if SnapshotBoard.first(:stroke => last_stroke.id).nil? then
							self.save last_stroke.id, last_event.id, user.session
						end
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

		def save last_stroke, last_event, session_id

			users = User.all(:session => session_id)
			zones = []

			users.each do |user|
				zones.push(@allocator[user.zone])
			end

			SnapshotBoard.new zones, last_stroke, last_event, session_id
		end
		
		#
		# Get the board state at stroke_id.
		# FIXME: load_board is not static because it depends on @config.
		#
		def load_board stroke_id, event_id
			
			if stroke_id < 0 then
				stroke_id = 0
			end
		
			# The first snap before stroke_max
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
			
			# get the session associated to the snapshot
			users_db = User.all(
				:session => snap.session
			)

			zones = users_db.map{ |u|
				Zone.from_hash snap.data[u.zone], @config.width, @config.height, u.id
			}

			strokes_db = Stroke.all(
				:id.gt => snap.stroke,
				:id.lte => stroke_id
			)
		
			events_db = Event.all(
				:id.gt => snap.event,
				:id.lte => event_id
			)
			
			users = users_db.map{ |u| u.to_hash }
			strokes = strokes_db.map{ |s| s.to_hash s.timestamp } # strokes with diffstamp = 0 (not important)
			events = events_db.map{ |e| e.to_hash zones[e.zone_index] }
			# TODO: apply events
			
			# Apply strokes
			zones.each do |zone|
				zone.apply_local strokes.select{ |s| s["zone"] == zone.index }
			end

			STDOUT.puts "users, zones, strokes and events"
			pp users
			pp zones
			pp strokes
			pp events
			
			return users, zones
		end
	end

end


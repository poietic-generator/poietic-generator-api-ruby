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

require 'poieticgen/allocation/spiral'
require 'poieticgen/allocation/random'

require 'monitor'

module PoieticGen

	#
	# A class that manages the global drawing
	#
	class Board
		include DataMapper::Resource

		property :id,            Serial
		property :timestamp,     Integer, :required => true
		property :session_token, String,  :required => true, :unique => true
		property :end_timestamp, Integer, :default => 0
		property :closed,        Boolean, :default => false
		property :allocator_type, String, :required => true
		# FIXME : maintain boundaries for the board
		# property :boundary_left, Integer, :default => 0
		# property :boundary_right, Integer, :default => 0
		# property :boundary_top, Integer, :default => 0
		# property :boundary_bottom, Integer, :default => 0

		has n, :board_snapshots
		has n, :timelines
		has n, :users
		has n, :zones

		STROKE_COUNT_BETWEEN_QFRAMES = 25

		attr_reader :config

		ALLOCATORS = {
			"spiral" => PoieticGen::Allocation::Spiral,
			"random" => PoieticGen::Allocation::Random,
		}


		def initialize config
			super({
				# FIXME: when the token already exists, SaveFailureError is raised
				:session_token => (0...16).map{ ('a'..'z').to_a[rand(26)] }.join,
				:timestamp => Time.now.to_i,
				:allocator_type => config.allocator
			})
		
			@debug = true
			rdebug "using allocator %s" % config.allocator

			# @allocator = ALLOCATORS[config.allocator].new config
			
			begin
				save
			rescue DataMapper::SaveFailureError => e
				pp e.resource.errors.inspect
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
		def close
			closed = true
			end_timestamp = Time.now.to_i
			
			begin
				save
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end


		#
		# Get access to zone with given index
		#
		def [] idx
			return zones.first(:index => idx)
		end

		def include? idx
			Board.transaction do
				val = self[idx]
				return (not val.nil?)
			end
		end


		#
		# make the user join the board
		#
		def join user
			zone = nil
			Board.transaction do
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
			Board.transaction do
				zone = self[user.zone]
				unless zone.nil? then
					# reset zone
					zone.reset
					# unallocate it
					@allocator.free user.zone
				else
					#FIXME: return an error to the user?
				end
			end
		end


		def update_data user, drawing
			return if drawing.empty?
		
			Board.transaction do
				
				# Update the zone
			
				zone = self[user.zone]
				unless zone.nil? then
					zone.apply user, drawing
				else
					#FIXME: return an error to the user ?
				end
				
				# Save board periodically
				
				stroke_count = timelines.strokes.first(
					:order => [ :id.desc ]
				)
				
				stroke_count = 0 if stroke_count.nil?
				
				if stroke_count % STROKE_COUNT_BETWEEN_QFRAMES == 0 then
					self.take_snapshot
				end
			end
		end

		def take_snapshot
			BoardSnapshot.new self
		end
		

		#
		# Get the board state at timeline_id.
		#
		def load_board timeline_id, apply_strokes
			snap = _get_snapshot timeline_id
			zones_snap = {}
			
			if snap.nil? then			
				# no snapshot: the board is empty
				snap_timeline = 0
			else
				snap_timeline = snap.timeline
				
				# Create zones from snapshot
				snap.zone_snapshots.each do |zs|
					zones_snap[zs.index] = Zone.from_snapshot zs
				end
			end
		
			# Put zones from snapshot in allocator
			allocator = ALLOCATORS[self.allocator_type].new @config, zones_snap
			
			# get the users associated to the snapshot
			users_db = self.users
			
			# get events since the snapshot
			timelines = self.timelines.all(
				:id.gt => snap_timeline,
				:id.lte => timeline_id,
				:order => [ :id.asc ]
			)
			
			# Add/Remove zones since the snapshot
			timelines.events.each do |event|
				zone_index = event.zone_index
				user_id = event.zone_user
				
				STDOUT.puts "%s user_id = %d, zone_index = %d" % [ event.type, user_id, zone_index ]
				if event.type == "join" then
					zone = allocator.allocate
					zone.user_id = user_id
				elsif event.type == "leave" then
					# reset zone
					allocator[zone_index].reset
					# unallocate it
					allocator.free zone_index
				else
					raise RuntimeError, "Unknown event type %s" % event.type
				end
			end
			
			users = users_db.map{ |u| u.to_hash } # FIXME: All users in the session are returned
			zones = allocator.zones
			
			if apply_strokes then
				strokes = timelines.strokes # strokes with diffstamp = 0 (not important)
			
				# Apply strokes
				zones.each do |index,zone|
					# FIXME: use allocator to test if zone is allocated	
					unless zone.user_id.nil? then
						zone.apply_local strokes.select{ |s| s.zone == zone.index }
					end
				end
			end
			
			return users, zones
		end
		
		private

		#
		# return the snapshot preceeding timeline_id
		#
		def _get_snapshot timeline_id
			timeline = self.timelines.first(
				:id.lte => timeline_id,
				:order => [ :id.desc ]
			)
			
			return timeline.board_snapshot
		end


		#
		# update boundaries of board
		#
		def _update_boundaries
			Board.transaction do

				@boundary_left = 0
				@boundary_top = 0
				@boundary_right = 0
				@boundary_bottom = 0

				@zones.each do |idx, zone|
					x,y = zone.position
					@boundary_left = x if x < @boundary_left
					@boundary_right = x if x > @boundary_right
					@boundary_top = y if y < @boundary_top
					@boundary_bottom = y if y > @boundary_bottom
				end

				rdebug "Spiral/_update_boundaries : ", { 
					:top => @boundary_top, 
					:left => @boundary_left,
					:right => @boundary_right,
					:bottom => @boundary_bottom
				}
			end
		end
	end

end


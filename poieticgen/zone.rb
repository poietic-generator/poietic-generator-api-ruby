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

module PoieticGen

	class Zone
		include DataMapper::Resource
		
		property :id,	Serial

		# the position, from center
		property :index, Integer, :required => true

		# position
		property :position, Json, :required => true
		# property :position, Csv, :required => true
	
		# size attributes
		property :width, Integer, :required => true
		property :height, Integer, :required => true
		
		property :data, Json, :required => true
		#property :data, Object, :required => true

		property :created_at, Integer, :required => true
		property :expired_at, Integer, :required => true, :default => 0
		property :expired, Boolean, :required => true, :default => false

		property :is_snapshoted, Boolean, :default => false

	#	attr_reader :index, :position

		belongs_to :board
		belongs_to :user
		has n, :zone_snapshots

		DESCRIPTION_MINIMAL = 1
		DESCRIPTION_FULL = 2
		
		#
		# convert JSON strings to integers
		#
		def position
			super.map{|x| x.to_i}
		end



		def initialize index, position, width, height, board
			# @debug = true

			param_create = {
				:index => index,
				:position => position.map{|x| x.to_s},
				:width => width,
				:height => height,
				:data => Array.new( width * height, '#000'),
				:user => nil,
				:created_at => Time.now.to_i,
				:board => board
			}
			super param_create
		end
		
		def save
			begin
				super
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
		def self.from_snapshot snapshot
			zone = snapshot.zone
			zone.data = snapshot.data
			
			return zone
		end

		def reset
			self.data = Array.new( width * height, '#000')
		end

		def disable
			self.expired_at = Time.now.to_i
			self.expired = true
		end

		def apply drawing
			Zone.transaction do
				# save patch into database
				return if drawing.nil? or drawing.empty?

				rdebug drawing.inspect if drawing.length != 0

				ref = self.user.last_update_time

				# Sort strokes by time
				drawing = drawing.sort{ |a, b| a['diff'].to_i <=> b['diff'].to_i }

				drawing.each do |patch|

					color = patch['color']
					changes = patch['changes']
					timestamp = patch['diff'].to_i + ref

					# add patch into database
					Stroke.create_stroke color,
						JSON.generate(changes).to_s,
						timestamp,
						self

					changes.each do |x,y,t_offset|
						idx = _xy2idx(x,y)
						self.data[idx] = color
					end
				end
				
				self.is_snapshoted = false

				self.save
			end
		end
		
		#
		# Apply a list of strokes object without saving it into the db
		#
		def apply_local drawing
			return if drawing.nil? or drawing.empty?

			rdebug drawing.inspect if drawing.length != 0

			drawing.each do |patch|

				color = patch.color
				changes = JSON.parse(patch.changes)

				changes.each do |x,y,t_offset|
					idx = _xy2idx(x,y)
					self.data[idx] = color
				end
			end
		end

		def to_desc_hash type
			res = nil
			Zone.transaction do
				res = {
					:index => self.index,
					:position => self.position,
					:user => self.user.id,
					:content => if type == DESCRIPTION_FULL
					            then self.to_patches_hash
					            else [] end
				}
			end
			return res
		end


		#
		# Return an array out of current zone state
		#
		def to_patches_hash
			result = []
			Zone.transaction do
				patches = {}

				self.width.times do |w|
					self.height.times do |h|
						color = self.data[_xy2idx(w,h)]
						next if color.nil?
						patches[color] = [] unless patches.include? color
						patches[color].push [w,h,0]
					end
				end
				patches.each do |color, where|
					patch = {
						:id => nil,
						:zone => self.index,
						:color => color,
						:changes => where,
						:diffstamp => nil
					}
					result.push patch
				end
			end
			return result
		end
		
		def snapshot timeline
			snap = nil

			unless self.is_snapshoted then
				Zone.transaction do
					self.is_snapshoted = true

					snap = _take_snapshot timeline

					self.save
				end
			else
				# last snapshot
				snap = self.zone_snapshots.timeline.first(:order => [ :id.desc ])
			end

			return snap
		end

		private

		def _xy2idx x,y
			return (y * self.width + x)
		end

		def _idx2xy idx
			x = idx % self.width
			y = idx / self.width
			return x,y
		end
		
		def _take_snapshot timeline
			ZoneSnapshot.create self.data, self, timeline
		end
	end
end

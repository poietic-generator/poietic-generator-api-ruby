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

		# user 
		property :user_id, Integer
		
		property :data, Json, :required => true
		#property :data, Object, :required => true

		property :created_at, Integer, :required => true
		property :deleted_at, Integer, :required => true
		property :deleted, Boolean, :required => true

	#	attr_reader :index, :position


		DESCRIPTION_MINIMAL = 1
		DESCRIPTION_FULL = 2
		
		def position
			super.map{|x| x.to_i}
		end

		def initialize index, position, width, height
			@debug = true

			param_create = {
				:index => index,
				:position => position.map{|x| x.to_s},
				:width => width,
				:height => height,
				:data => Array.new( width * height, '#000'),
				:user_id => nil,
				:created_at => Time.now.to_i,
				:deleted_at => 0,
				:deleted => false
			}
			super param_create
			
			@last_snapshot = nil
			@is_snapshoted = false
		end
		
		def save
			begin
				# FIXME: debug
				pp self
				super
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
			rdebug "zone created!"
		end
		
		def self.from_snapshot snapshot
			pp snapshot.index
			pp snapshot.position
			zone = Zone.new snapshot.index, snapshot.position, snapshot.width, snapshot.height
			zone.user_id = snapshot.user_id
			zone.data = snapshot.data
			
			return zone
		end

		def reset
			self.data = Array.new( width * height, '#000');
			begin
				self.save
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end

		def apply user, drawing
			Zone.transaction do
				# save patch into database
				return if drawing.nil? or drawing.empty?

				rdebug drawing.inspect if drawing.length != 0

				# FIXME: get user from user_id
				ref = user.last_update_time

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
						user.zone,
						user.session

					changes.each do |x,y,t_offset|
						idx = _xy2idx(x,y)
						self.data[idx] = color
					end
				end
				
				@is_snapshoted = false

				begin
					self.save
				rescue DataMapper::SaveFailureError => e
					rdebug "Saving failure : %s" % e.resource.errors.inspect
					raise e
				end
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
					:user => self.user_id,
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
		
		def snapshot
			if not @is_snapshoted then
				@last_snapshot = _take_snapshot
			end
			
			return @last_snapshot
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
		
		def _take_snapshot
			ZoneSnapshot.new ({
				:index => self.index,
				:position => self.position,
				:width => self.width,
				:height => self.height,
				:user_id => self.user_id,
				:data => self.data
			})
		end
	end
end

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

require 'monitor'

module PoieticGen
	class Zone
		include DataMapper::Resource

		property :id,	Serial

		# the position, from center
		property :index, Integer, :required => true

		# position
		property :position, Csv, :required => true
	
		# size attributes
		property :width, Integer, :required => true
		property :height, Integer, :required => true

		# user 
		property :user_id, Integer 

		property :created_at, Integer, :required => true
		property :deleted_at, Integer, :required => true
		property :deleted, Boolean, :required => true

		property :data, Csv, :required => true

	#	attr_reader :index, :position

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

			begin
				self.save
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
			rdebug "zone created!"
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
				return if drawing.nil?

				rdebug drawing.inspect if drawing.length != 0

				# FIXME: get user from user_id
				ref = user.last_update_time

				drawing.each do |patch|

					color = patch['color']
					changes = patch['changes']
					timestamp = patch['diff'].to_i + ref

					# add patch into database
					param_create = {
						:color => color,
						:changes => JSON.generate(changes).to_s,
						:timestamp => timestamp,
						:zone => user.zone
					}
					begin
						patch = Stroke.create param_create
						patch.save
					rescue DataMapper::SaveFailureError => e
						rdebug "Saving failure : %s" % e.resource.errors.inspect
						raise e
					end

					changes.each do |x,y,t_offset|
						idx = _xy2idx(x,y)
						self.data[idx] = color
					end
				end

				begin
					self.save
				rescue DataMapper::SaveFailureError => e
					rdebug "Saving failure : %s" % e.resource.errors.inspect
					raise e
				end
			end
		end

		def to_desc_hash
			res = nil
			Zone.transaction do
				res = {
					:index => self.index,
					:position => self.position,
					:user => self.user_id,
					:content => self.to_patches_hash
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
						:stamp => nil
					}
					result.push patch
				end
			end
			return result
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
	end
end

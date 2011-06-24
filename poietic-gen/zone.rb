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

		attr_reader :index, :position

		attr_accessor :user

		def initialize index, position, width, height
			@index = index
			@position =	position
			@width = width
			@height = height
			@user = nil

			@data = []
			@width.times do |w_cnt|
				@data[w_cnt] = []
				@height.times do |h_cnt|
					@data[w_cnt][h_cnt] = nil
				end
			end
			@monitor = Monitor.new
			@debug = true
		end

		def apply user, drawing
			@monitor.synchronize do
				# save patch into database
				return if drawing.nil?

				rdebug drawing.inspect if drawing.length != 0

				drawing.each do |patch|


					color = patch['color']
					changes = patch['changes']
					timestamp = patch['stamp']

					# add patch into database
					param_create = {
						:color => color,
						:changes => JSON.generate(changes).to_s,
						:timestamp => DateTime.parse(timestamp),
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
						@data[x][y] = color
					end
				end
			end
		end

		def to_desc_hash
			res = nil
			@monitor.synchronize do
				res = {
					:index => @index,
					:position => @position,
					:user => @user.id,
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
			@monitor.synchronize do
				patches = {}
				@width.times do |w|
					@height.times do |h|
						color = @data[w][h]
						next if color.nil?
						patches[color] = [] unless patches.include? color
						patches[color].push [w,h,0]
					end
				end
				patches.each do |color, where|
					patch = {
						:id => nil,
						:zone => @index,
						:color => color,
						:changes => where,
						:stamp => nil
					}
					result.push patch
				end
			end
			return result
		end
	end
end

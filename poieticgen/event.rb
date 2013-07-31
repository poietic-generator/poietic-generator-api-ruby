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

require 'dm-core'
require 'json'

module PoieticGen
	class Event
		include DataMapper::Resource

		# @debug = true

		property :id,	Serial
		property :type,	String, :required => true

		belongs_to :timeline, :key => true
		belongs_to :user

		def self.create_join user, board
			begin
				event = Event.create({
					:type => 'join',
					:user => user,
					:timeline => (Timeline.create_now board)
				})
			rescue DataMapper::SaveFailureError => e
				pp "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
			
		end

		def self.create_leave user, board
			begin
				event = Event.create({
					:type => 'leave',
					:user => user,
					:timeline => (Timeline.create_now board)
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
		def to_hash ref
			res_desc = {
				:user => self.user.to_hash,
				:zone => (self.user.zone.to_desc_hash Zone::DESCRIPTION_MINIMAL)
			}

			res = {
				:id => self.timeline.id,
				:type => self.type,
				:desc => res_desc,
				:diffstamp => self.timeline.timestamp - ref
			}
			return res
		end
		
	end

end

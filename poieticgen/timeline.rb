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

require 'poieticgen/zone'

module PoieticGen

	class Timeline
		include DataMapper::Resource

		property :id,	Serial
		property :timestamp, Integer

		has 1, :event
		has 1, :stroke
		has 1, :message
		has 1, :board_snapshot
		
		belongs_to :session
		
		# @debug = true
		
		def self.create_now session
			create({
				:timestamp => Time.now.to_i,
				:session => session
			})
		end
		
		def self.create_with_time timestamp, session
			create({
				:timestamp => timestamp,
				:session => session
			})
		end

		def self.last_id session
			last_timeline = session.timelines.first(:order => [ :id.desc ])
			if last_timeline.nil? then 0 else last_timeline.id end
		end

	end
end

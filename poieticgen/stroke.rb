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

	class Stroke
		include DataMapper::Resource

		property :id,	Serial
		property :zone, Integer, :required => true
		property :color, String, :required => true
		property :changes, Text, :required => true, :lazy => false
		property :timestamp, Integer, :required => true

		def to_hash ref
			res = {
				:id => self.id,
				:zone => self.zone,
				:color => self.color,
				:changes => JSON.parse( self.changes ),
				:diffstamp => self.timestamp - ref
			}
			return res
		end
	end
end

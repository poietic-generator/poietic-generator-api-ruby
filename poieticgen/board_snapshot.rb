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
require 'poieticgen/zone_snapshot'
require 'poieticgen/session'

module PoieticGen
	
	class BoardSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		has n, :zone_snapshots, :through => Resource
		belongs_to :timeline
		belongs_to :session

		def initialize zones, last_timeline, session
			@debug = true
			
			json = {
				:session => session,
				:timeline => last_timeline,
				:zone_snapshots => []
				
			}
			super json

			zones.each do |index, zone|
				self.zone_snapshots<< zone.snapshot
			end

			begin
				self.save
				pp self
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
	end
end

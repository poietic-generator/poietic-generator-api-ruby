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

module PoieticGen
	
	class BoardSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		has n, :zone_snapshots, :through => Resource
		belongs_to :timeline
		belongs_to :board

		def self.create board
			# @debug = true

			zone_snaps = []
			timeline = Timeline.create_now board

			board.zones.each do |zone|
				unless zone.expired then
					zone_snaps.push (zone.snapshot timeline)
				end
			end

			begin
				super ({
					:board => board,
					:timeline => timeline,
					:zone_snapshots => zone_snaps
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
	end
end

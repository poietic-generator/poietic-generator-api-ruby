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

	class SnapshotBoard
		include DataMapper::Resource

		property :id,	Serial
		property :session, String, :required => true
		property :stroke, Integer, :required => true, :unique => true
		property :event, Integer, :required => true
		property :data, Json, :required => true

		def initialize zones, last_stroke, session_id
			@debug = true
			
			json = {
				:session => session_id,
				:stroke => last_stroke,
				:data => zones.map{ |z| z.to_desc_hash Zone::DESCRIPTION_FULL }
			}
			super json

			begin
				pp self
				self.save
			rescue DataMapper::SaveFailureError => e
				pp e
				# TODO: ignore if dupplicate entry for stroke
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end

		def to_hash
			res = nil
			SnapshotBoard.transaction do
				res = self.data
			end
			return res
		end
		
	end
end

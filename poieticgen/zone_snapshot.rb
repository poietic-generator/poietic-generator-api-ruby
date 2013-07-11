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

	class ZoneSnapshot
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
		
		has n, :board_snapshots, :through => Resource

		def initialize json
			@debug = true
			
			super json

			begin
				self.save
				pp self
			rescue DataMapper::SaveFailureError => e
				pp e.resource.errors.inspect
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end

		def to_hash
			res = nil
			ZoneSnapshot.transaction do
				res = self.data
			end
			return res
		end
		
	end
end

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
require 'poieticgen/session'

module PoieticGen

	class User

		include DataMapper::Resource

		property :id,	Serial
		property :name,	String, :required => true
		property :zone, Integer, :required => true
		property :created_at, Integer, :required => true
		property :alive_expires_at, Integer, :required => true
		property :idle_expires_at, Integer, :required => true
		property :did_expire, Boolean, :required => true
		property :last_update_time, Integer, :required => true
		property :is_admin, Boolean, :default => false
		
		belongs_to :session
		
		# @debug = true

		def to_hash
			res = {
				:id => self.id,
				:name => self.name,
				:zone => self.zone
			}
			return res
		end
	end

end

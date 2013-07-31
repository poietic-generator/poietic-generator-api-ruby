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
require 'poieticgen/board'

module PoieticGen

	class User

		include DataMapper::Resource

		property :id,	Serial
		property :name,	String, :required => true
		property :created_at, Integer, :required => true
		property :alive_expires_at, Integer, :required => true
		property :idle_expires_at, Integer, :required => true
		property :did_expire, Boolean, :required => true, :default => false
		property :last_update_time, Integer, :required => true
		
		belongs_to :board
		has 1, :zone
		
		# @debug = true

		def initialize name, board, config
			now = Time.now

			super({
				:board => board,
				:name => name,
				:zone => nil,
				:created_at => now.to_i,
				:alive_expires_at => (now + config.liveness_timeout).to_i,
				:idle_expires_at => (now + config.idle_timeout).to_i,
				:last_update_time => now
			})
		end

		def expired?
			now = Time.now.to_i
			return (self.did_expire or
				now >= self.alive_expires_at or
				now >= self.idle_expires_at)
		end

		def set_expired
			now = Time.now.to_i
			if self.alive_expires_at > now then
				self.alive_expires_at = now
			end
			if self.idle_expires_at > now then
				self.idle_expires_at = now
			end
			self.did_expire = true
		end

		def to_hash
			res = {
				:id => self.id,
				:name => self.name,
				:zone => self.zone.index
			}
			return res
		end
	end

end

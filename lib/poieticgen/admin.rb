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

module PoieticGen

	class Admin

		include DataMapper::Resource

		property :id,	Serial
		property :token, String, :required => true, :unique => true
		property :name,	String, :required => true
		property :created_at, Integer, :required => true
		property :expires_at, Integer, :required => true
		property :did_expire, Boolean, :required => true, :default => false
		property :last_update_time, Integer, :required => true
		
		# @debug = true

		def self.create name, config
			now = Time.now

			super({
				:token => (0...32).map{ ('a'..'z').to_a[rand(26)] }.join,
				:name => name,
				:created_at => now.to_i,
				:expires_at => (now + config.idle_timeout).to_i,
				:last_update_time => now
			})
		end


		def expired?
			now = Time.now.to_i
			return (self.did_expire or
				now >= self.expires_at)
		end


		def set_expired
			now = Time.now.to_i
			if self.expires_at > now then
				self.expires_at = now
			end
			self.did_expire = true
			self.save
		end


		def report_expiration config
			self.expires_at = (Time.now + config.idle_timeout).to_i
			self.did_expire = false
			self.save
		end
	end

end

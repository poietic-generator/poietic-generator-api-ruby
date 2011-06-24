##############################################################################
#                                                                            #
#  Poetic Generator Reloaded is a multiplayer and collaborative art          #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011 - Gnuside                                              #
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
	class Message
		include DataMapper::Resource

		property :id,	Serial
		property :user_src,	Integer, :required => true
		property :user_dst,	Integer, :required => true
		property :content, Text, :required => true
		property :stamp,	DateTime, :required => true


		def to_hash
			res = {
				:id => self.id,
				:user_src => self.user_src,
				:user_dst => self.user_dst,
				:content => self.content,
				:stamp => self.stamp
			}
			return res
		end

		def self.post src, dst, stamp, content
			begin
				msg = Message.create({
					:user_src => src,
					:user_dst => dst,
					:content => content,
					:stamp => stamp
				})
				msg.save
			rescue DataMapper::SaveFailureError => e
				puts e.resource.errors.inspect
				raise e
			end
		end
	end

end

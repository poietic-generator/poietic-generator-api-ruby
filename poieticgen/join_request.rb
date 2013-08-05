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


module PoieticGen
	class JoinRequestParseError < OptionParser::ParseError ; end

	class JoinRequest

		USER_TOKEN = 'user_token'
		SESSION_TOKEN = 'session_token'
		USER_NAME = 'user_name'

		SINATRA_SPLAT = 'splat'
		SINATRA_CAPTURES = 'captures'

		private

		def initialize hash
			@hash = hash
			# @debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when USER_NAME then
				  	rdebug "user_name : %s" % val.inspect
				when USER_TOKEN then
				  	rdebug "user_token : %s" % val.inspect
				when SESSION_TOKEN then
					rdebug "session_token : %s" % val.inspect
				when SINATRA_SPLAT then
					rdebug "sinatra splat : %s" % val.inspect
				when SINATRA_CAPTURES then
					rdebug "sinatra captures : %s" % val.inspect
				else
					raise JoinRequestParseError, "Unknow request field '%s'" % key
				end
			end

			[
				SESSION_TOKEN
			].each do |field|
				unless hash.include? field then
					raise JoinRequestParseError, ("The '%s' field is missing" % field)
				end
			end

			JoinRequest.new hash
		end


		def user_token
			return @hash[USER_TOKEN]
		end

		def user_name
			return @hash[USER_NAME]
		end
    		
    		def session_token
			return @hash[SESSION_TOKEN]
		end

	end
end


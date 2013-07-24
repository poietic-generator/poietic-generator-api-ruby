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
	class UpdateViewRequestParseError < OptionParser::ParseError ; end

	class UpdateViewRequest

		DURATION = 'duration'

		TIMELINE_AFTER = 'timeline_after'
		LAST_MAX_TIMESTAMP = 'last_max_timestamp'
		
		SINCE = 'since'
		ID = 'id'
		VIEW_MODE = 'view_mode'
		
		SESSION_TOKEN = 'session_token'
		SINATRA_SPLAT = 'splat'
		SINATRA_CAPTURES = 'captures'
		
		REAL_TIME_VIEW = 0
		HISTORY_VIEW = 1

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
				when DURATION then
					rdebug "duration : %s" % val.inspect
				when TIMELINE_AFTER then
					rdebug "timeline_after : %s" % val.inspect
				when LAST_MAX_TIMESTAMP then
					rdebug "last_max_timestamp : %s" % val.inspect
				when SINCE then
					rdebug "since : %s" % val.inspect
				when ID then
					rdebug "id : %s" % val.inspect
				when VIEW_MODE then
					rdebug "view_mode : %s" % val.inspect
				when SESSION_TOKEN then
					rdebug "session : %s" % val.inspect
				when SINATRA_SPLAT then
					rdebug "sinatra splat : %s" % val.inspect
				when SINATRA_CAPTURES then
					rdebug "sinatra captures : %s" % val.inspect
				else
					raise UpdateViewRequestParseError, "Unknow request field '%s'" % key
				end
			end

			[
				DURATION,
				TIMELINE_AFTER,
				SINCE,
				ID,
				VIEW_MODE,
				SESSION_TOKEN
			].each do |field|
				unless hash.include? field then
					raise UpdateViewRequestParseError, ("The '%s' field is missing" % field)
				end
			end
			UpdateViewRequest.new hash
		end


		def duration
			return @hash[DURATION].to_i
		end

		def timeline_after
			return @hash[TIMELINE_AFTER].to_i
		end

		def last_max_timestamp
			return @hash[LAST_MAX_TIMESTAMP].to_i
		end
		
		def since
			return @hash[SINCE].to_i
		end
		
		def id
			return @hash[ID].to_i
		end
		
		def view_mode
			return @hash[VIEW_MODE].to_i
		end
		
		def session_token
			return @hash[SESSION_TOKEN]
		end
	end

end


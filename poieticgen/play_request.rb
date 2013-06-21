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
	class PlayRequest

		SINCE = 'since'
		DURATION = 'duration'
		SESSION = 'session'

		STROKES_AFTER = 'strokes_after'
		EVENTS_AFTER = 'events_after'

		private

		def initialize hash
			@hash = hash
			@enable_strokes = false
			@enable_events = false
			@enable_messages = false
			@debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when SINCE then
					rdebug "since : %s" % val.inspect
				when DURATION then
					rdebug "duration : %s" % val.inspect
				when SESSION then
					rdebug "session : %s" % val.inspect
				when STROKES_AFTER then
					@enable_strokes = true
				when EVENTS_AFTER then
					@enable_events = true
				else
					raise RuntimeError, "unknow request field '%s'" % key
				end
			end

			[
				SINCE,
				DURATION,
				SESSION
			].each do |field|
				unless hash.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
				end
			end
			PlayRequest.new hash
		end


		def since
			return @hash[SINCE].to_i
		end

		def duration
			return @hash[DURATION].to_i
		end

		def session
			return @hash[SESSION]
		end

		def events_after
			return @hash[EVENTS_AFTER].to_i
		end

		def strokes_after
			return @hash[STROKES_AFTER].to_i
		end
	end

end


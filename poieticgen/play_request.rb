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

		DURATION = 'duration'
		SESSION = 'session'

		STROKES_AFTER = 'strokes_after'
		
		SINCE_STROKE = 'since_stroke'
		ID = 'id'
		VIEW_MODE = 'view_mode'
		
		REAL_TIME_VIEW = 0
		HISTORY_VIEW = 1

		private

		def initialize hash
			@hash = hash
			@enable_strokes = false
			@debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when DURATION then
					rdebug "duration : %s" % val.inspect
				when SESSION then
					rdebug "session : %s" % val.inspect
				when STROKES_AFTER then
					@enable_strokes = true
				when SINCE_STROKE then
					rdebug "since_stroke : %s" % val.inspect
				when ID then
					rdebug "id : %s" % val.inspect
				when VIEW_MODE then
					rdebug "view_mode : %s" % val.inspect
				else
					raise RuntimeError, "unknow request field '%s'" % key
				end
			end

			[
				DURATION,
				SESSION,
				STROKES_AFTER,
				SINCE_STROKE,
				ID,
				VIEW_MODE
			].each do |field|
				unless hash.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
				end
			end
			PlayRequest.new hash
		end


		def duration
			return @hash[DURATION].to_i
		end

		def session
			return @hash[SESSION]
		end

		def strokes_after
			return @hash[STROKES_AFTER].to_i
		end
		
		def since_stroke
			return @hash[SINCE_STROKE].to_i
		end
		
		def id
			return @hash[ID].to_i
		end
		
		def view_mode
			return @hash[VIEW_MODE].to_i
		end
	end

end


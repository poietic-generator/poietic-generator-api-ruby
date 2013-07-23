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
	class UpdateRequest

		MESSAGES = 'messages'
		STROKES = 'strokes'

		TIMELINE_AFTER = 'timeline_after'

		TIMELINE_BEFORE = 'timeline_before'

		MESSAGES_DST = 'user_dst'
		MESSAGES_CONTENT = 'content'
		MESSAGES_STAMP = 'stamp'

		UPDATE_INTERVAL = 'update_interval'

		private

		def initialize hash
			@hash = hash
			@enable_timeline = false # FIXME: unused
			# @debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when TIMELINE_AFTER then
					@enable_timeline = true
				when TIMELINE_BEFORE then
					@enable_timeline = true
				when MESSAGES then
					if val.length != 0 then
						rdebug "messages : %s" % val.inspect
          				end
				when STROKES then
				  	if val.length != 0 then
						rdebug "strokes : %s" % val.inspect
         				end
				when UPDATE_INTERVAL then
				  	begin
				    		rdebug "update_interval : %d" % val.to_i
				  	rescue Exception => e
				    		rdebug e
				    		raise ArgumentError, ("%s with invalid value : " % UPDATE_INTERVAL)
					end
				else
					raise RuntimeError, "unknow request field '%s'" % key
				end
			end

			[
				TIMELINE_AFTER,
				STROKES,
				MESSAGES,
				UPDATE_INTERVAL
			].each do |field|
				unless hash.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
				end
			end
			# parse per-field content
			#
			hash[MESSAGES].each do |msg|
				[ 	MESSAGES_DST,
					MESSAGES_CONTENT,
					MESSAGES_STAMP
				].each do |field|
					unless msg.include? field then
						raise ArgumentError, ("The '%s' sub-field is missing" % field)
					end
				end
				# FIXME: msg[MESSAGES_DST].to_i
			end
			UpdateRequest.new hash
		end


		def strokes
			return @hash[STROKES]
		end

		def messages
			return @hash[MESSAGES]
		end

		def timeline_after
			return @hash[TIMELINE_AFTER].to_i
		end

		def update_interval
		  return @hash[UPDATE_INTERVAL].to_i
    		end

	end
end


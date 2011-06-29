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

module PoieticGen
	class SnapshotRequest

		DATE = 'date'

		private

		def initialize hash
			@hash = hash
			@debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when DATE then
					rdebug "date : %s" % val.inspect
				else
					raise RuntimeError, "unknow request field '%s'" % key
				end
			end

			[
				DATE
			].each do |field|
				unless hash.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
				end
			end
			SnapshotRequest.new hash
		end


		def date
			return @hash[DATE]
		end

	end

end


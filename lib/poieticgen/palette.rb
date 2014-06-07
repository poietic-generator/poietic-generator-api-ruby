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

	class Palette < Array
		def initialize
			super

			self[ 0] = "#FFFFFF"
			self[ 1] = "#C0C0C0"
			self[ 2] = "#808080"
			self[ 3] = "#000000"
			self[ 4] = "#FF0000"
			self[ 5] = "#800000"
			self[ 6] = "#FFFF00"
			self[ 7] = "#808000"
			self[ 8] = "#00FF00"
			self[ 9] = "#008000"
			self[10] = "#00FFFF"
			self[11] = "#008080"
			self[12] = "#0000FF"
			self[13] = "#000080"
			self[14] = "#FF00FF"
			self[15] = "#800080"
		end
	end

end

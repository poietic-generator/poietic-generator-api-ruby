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

module PoieticGen ; class ConfigManager

	#
	#
	#
	class ConfigBoard

		attr_reader :name
		attr_reader :allocator
		attr_reader :colors
		attr_reader :width
		attr_reader :height
		# FIXME : fix width and height name

		#
		#
		#
		def initialize hash
			raise MissingField, "Board.name" unless hash.include? "name"
			@name = hash["name"]

			raise MissingField, "Board.allocator" unless hash.include? "allocator"
			case hash["allocator"].strip.downcase
			when /^spiral$/ then @allocator = "spiral"
			when /^random$/ then @allocator = "random"
			else raise BadFieldType, "Board.adapter must be [spiral|random]"
			end

			raise MissingField, "Board.colors" unless hash.include? "colors"
			case hash["colors"].strip.downcase
			when /^ansi$/ then @colors = "ansi"
			when /^truecolor$/ then @colors = "truecolor"
			else raise BadFieldType, "Board.color must be [ansi|truecolor]"
			end

			raise MissingField, "Board.width" unless hash.include? "width"
			@width = ConfigManager.parse_int hash["width"], "Board.width"

			raise MissingField, "Board.height" unless hash.include? "height"
			@height = ConfigManager.parse_int hash["height"], "Board.height"
		end
	end

end ; end


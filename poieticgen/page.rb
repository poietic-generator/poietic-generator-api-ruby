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
	#
	#
	#
	class Page < Struct.new :title, :css, :js
		#
		#
		#
		def initialize title="untitled", css=[], js=[]
			super
		end

		def render_css
			res = ""
			css.each do |css_file|
				res << "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{css_file}\" />\n"
			end
			return res
		end

		def render_js
			res = ""
			js.each do |js_file|
				res << "<script type=\"text/javascript\" src=\"#{js_file}\"></script>\n"
			end
			return res
		end
	end
end

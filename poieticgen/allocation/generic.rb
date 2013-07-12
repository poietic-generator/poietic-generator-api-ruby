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

module PoieticGen ; module Allocation

	class Generic

		#
		# return a zone, somewhere...
		#
		def allocate
			raise NotImplementedError
		end

		#
		# free zone at given index
		#
		def free idx
			raise NotImplementedError
		end

		#
		# get position for given index
		#
		def idx_to_pos idx
			raise NotImplementedError
		end

		#
		# get zone at given index
		#
		def [] index
			raise NotImplementedError
		end

		#
		# get all zones
		#
		def zones
			raise NotImplementedError
		end
		
		#
		# replace zones
		#
		def set_zones zones
			raise NotImplementedError
		end

		# 
		# get index for given position
		# (or raise something if not allocated)
		#
		def pos_to_idx x, y
			raise NotImplementedError
		end

	end

end ; end


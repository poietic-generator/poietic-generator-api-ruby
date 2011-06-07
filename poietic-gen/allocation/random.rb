
require 'poietic-gen/allocation/generic'

module PoieticGen ; module Allocation

	module Random < Generic

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
		# get index for given position
		# (or raise something if not allocated)
		#
		def pos_to_idx x, y
			raise NotImplementedError
		end

	end

end ; end


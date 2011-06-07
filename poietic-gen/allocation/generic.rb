
module PoieticGen ; module Allocation

	module Generic

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
		# get index for given position
		# (or raise something if not allocated)
		#
		def pos_to_idx x, y
			raise NotImplementedError
		end

	end

end ; end


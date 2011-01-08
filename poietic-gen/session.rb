
require 'poietic-gen/palette'


module PoieticGen

	#
	# manage a pool of users
	#
	class Session
		def initialize
			@palette = Palette.new
		end

		def join 
		end

		# post
		#  * <user-id> changes
		#
		# returns 
		#  * latest content since last update
		def sync user_id
			# 
			draw user_id

			return
		end

		#
		# Relocate user offset
		def draw user_id, change

		end
	end

end

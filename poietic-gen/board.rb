
module PoieticGen

	class Board
		@zones = [ ZONE_INIT ]
		ZONE_INIT = []


		# 
		# allocates a zone for a new user
		# uses the minimal index zone if it exists
		# or creates one if necessary
		# and return its index
		#
		def allocate 
			zone_result = nil

			zones_free = @zones.select do |zone_item|
				zone_item.user.nil?
			end
			if zones_free.empty? then
				self.expand!
			end

			zone = zones_free.first
			zone.user = user_id
			return zone
		end

		def free zone_idx
			zone = @zones[zone_idx]
			zone.user = nil
		end
	end
end


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

		#
		# expend map creating new allocatable zones
		#
		def world_expand
			# choose a side (using a spiral growth)
			# expand that side
			zone_past = @zones.last

			zone_present = Zone.create_next zone_past
			zone_future = Zone.create_next zone_past

			# if the following collides, then keep the same vector
			res = @zones.select do |zone_item|
				( zone_item.position <=> zone_future ) == 0
			end
			unless res.empty? then
				#collision with existing zone coordinates
				zone_present.vector = zone_past.vector
			end
			@zones << zone_present
		end

		#
		# reduce map removing unused zones from the border
		#
		def world_reduce
			while true
				zone = @zones.last
				break if @zones.last
			end
		end
	end
end

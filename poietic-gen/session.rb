
require 'poietic-gen/palette'


module PoieticGen

	class Zone <
		Struct :index, :position, :vector, :user

		def initialize index, position, vector
			@index = index
			@position = position
			@vector = vector
			@user = nil
		end

		def next_index
			return (@index + 1)
		end

		def next_position
			x = @position[0] + @vector[0]
			y = @position[1] + @vector[1]
			return [x,y]
		end

		def next_vector
			v = [ - @vector[1], @vector[0] ]
			return v
		end

		def self.create_next zone
			return self.new zone.next_index, zone.next_position, zone.next_vector
		end

	end
	ZONE_INIT = Zone.new 0, [0,0], [1,0]

	#
	# manage a pool of users
	#
	class Session
		def initialize
			@id = "xyz" # FIXME: must be a 8-char random string

			@palette = Palette.new
			@width = 32
			@height = 32

			@users = []
			@users_upcount = 0

			@zones = [ ZONE_INIT ]
		end


		#
		# generates an unpredictible user id based on session id & user counter
		#
		def join
			user_id = @id + @users_upcount
			@users_upcount += 1
			zone = self.zone_alloc user_id
		end

		def leave user_id
			zone_idx = @users[user_id].zone

			self.zone_free zone_idx
		end

		def zone_free zone_idx
			zone = @zones[zone_idx]
			zone.user = nil
		end

		#
		# allocates a zone for a new user
		# uses the minimal index zone if it exists
		# or creates one if necessary
		#
		def zone_alloc user_id
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

		# post
		#  * <user-id> changes
		#
		# returns 
		#  * latest content since last update
		def sync user_id
			# 
			#draw user

			return
		end

		#
		# Relocate user offset
		def draw user_id, change

		end
	end
end

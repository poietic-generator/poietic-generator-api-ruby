
require 'poieticgen/zone'

module PoieticGen

	class ZoneSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		property :pixel_data, Text, required: true, lazy: false
		
		has n, :board_snapshots, through: Resource
		belongs_to :timeline, key: true
		belongs_to :zone

		def self.create zone, timeline
			# @debug = true
			begin
				super ({
					pixel_data: zone.pixel_data,
					zone: zone,
					timeline: timeline
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
	end
end


require 'poieticgen'

module PoieticGen

	class ZoneSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		property :data, Json, required: true, lazy: false
		
		has n, :board_snapshots, through: Resource
		belongs_to :timeline, key: true
		belongs_to :zone

		def self.create zone, timeline
			super ({
				data: zone.data,
				zone: zone,
				timeline: timeline
			})
		end
	end
end

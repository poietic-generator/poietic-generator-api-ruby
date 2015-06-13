
require 'poieticgen/zone'

module PoieticGen

	class ZoneSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		property :data, Json, :required => true
		
		has n, :board_snapshots, :through => Resource
		belongs_to :timeline, :key => true
		belongs_to :zone

		def self.create zone, timeline
			# @debug = true
			begin
				super ({
					:data => zone.data,
					:zone => zone,
					:timeline => timeline
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
	end
end

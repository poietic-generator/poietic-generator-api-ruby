
require 'poieticgen'

module PoieticGen
	
	class BoardSnapshot
		include DataMapper::Resource
		
		property :id,	Serial
		
		has n, :zone_snapshots, :through => Resource
		belongs_to :timeline
		belongs_to :board

		def self.create board
			# @debug = true

			begin
				super ({
					:board => board,
					:timeline => (Timeline.create_now board)
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
	end
end

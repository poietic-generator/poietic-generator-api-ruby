
require 'poieticgen/zone'
require 'poieticgen/timeline'

module PoieticGen

	class Stroke
		include DataMapper::Resource

		property :id,	Serial
		property :color, String, :required => true
		property :changes, Text, :required => true, :lazy => false
		
		belongs_to :timeline, :key => true
		belongs_to :zone

		def self.create_stroke color, changes, timestamp, zone
			begin
				create ({
					:color => color,
					:changes => changes,
					:zone => zone,
					:timeline => (Timeline.create_with_time timestamp, zone.board)
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end

		def to_hash ref
			res = {
				:id => self.timeline.id,
				:zone => self.zone.index,
				:color => self.color,
				:changes => JSON.parse( self.changes ),
				:diffstamp => self.timeline.timestamp - ref
			}
			return res
		end
	end
end

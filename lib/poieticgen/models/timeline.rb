
require 'poieticgen'

module PoieticGen

	class Timeline
		include DataMapper::Resource

		property :id,	Serial
		property :timestamp, Integer

		has 1, :event
		has 1, :stroke
		has 1, :message
		# has 1, :board_snapshot
		# has 1, :zone_snapshot
		
		belongs_to :board
		
		def self.create_now board
			create({
				:timestamp => Time.now.to_i,
				:board => board
			})
		end
		
		def self.create_with_time timestamp, board
			create({
				:timestamp => timestamp,
				:board => board
			})
		end

		def self.last_id board
			last_timeline = board.timelines.first(order: [:id.desc])
			if last_timeline.nil? then 0 else last_timeline.id end
		end

	end
end

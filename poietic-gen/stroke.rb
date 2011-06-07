
require 'datamapper'

module PoieticGen

	class Stroke
		include DataMapper::Resource

		property :id,	Serial
		property :color, String, :required => true
		property :changes, Text, :required => true, :lazy => false
		property :timestamp,	DateTime

		def to_hash
			res = {
				:id => self.id,
				:color => self.color,
				:changes => JSON.parse( self.changes ),
				:stamp => self.timestamp
			}
			return res
		end
	end
end

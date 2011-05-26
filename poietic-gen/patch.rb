
require 'datamapper'

module PoieticGen

	class Drawing
		include DataMapper::Resource

		property :id,	Serial
		property :color, String
		property :changes, String
		property :timestamp,	DateTime
	end
end

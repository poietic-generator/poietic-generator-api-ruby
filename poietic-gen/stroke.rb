
require 'datamapper'

module PoieticGen

	class Stroke
		include DataMapper::Resource

		property :id,	Serial
		property :color, String, :required => true
		property :changes, Text, :required => true, :lazy => false
		property :timestamp,	DateTime
	end
end

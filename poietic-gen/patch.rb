
require 'datamapper'

module PoeticGen

	class Patch
		include DataMapper::Resource
		property :id,	Serial
		property :color, String
		property :coordinates, String
		property :timestamp,	DateTime
	end
end


require 'dm-core'

module PoieticGen
	class Event
		include DataMapper::Resource

		property :id,	Serial
		property :type,	String, :required => true
		property :desc, String, :required => true
		property :timestamp,	DateTime
	end

end

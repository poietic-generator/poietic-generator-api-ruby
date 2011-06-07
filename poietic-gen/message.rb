
require 'dm-core'
require 'json'

module PoieticGen
	class Message
		include DataMapper::Resource

		property :id,	Serial
		property :type,	String, :required => true
		property :desc, String, :required => true
		property :timestamp,	DateTime


		def to_hash
			res = {
				:id => self.id,
				:type => self.type,
				:desc => JSON.parse(self.desc),
				:stamp => self.timestamp
			}
			return res
		end
	end

end

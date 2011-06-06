
require 'dm-core'
require 'json'

module PoieticGen
	class Event
		include DataMapper::Resource

		property :id,	Serial
		property :type,	String, :required => true
		property :desc, String, :required => true
		property :timestamp,	DateTime


		def self.create_join uid, uzone
			event = Event.create({ 
				:type => 'join', 
				:desc => JSON.generate({ :user => uid, :zone => uzone }),
				:timestamp => DateTime.now
			})
			event.save
		end

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


require 'dm-core'
require 'json'

module PoieticGen
	class Event
		include DataMapper::Resource

		@debug = true

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

		def self.create_leave uid, leave_time, uzone
			event = Event.create({
				:type => 'leave',
				:desc => JSON.generate({ :user => uid, :zone => uzone }),
				:timestamp => leave_time
			})
			event.save
		end

		def to_hash board
			desc = JSON.parse( self.desc )
			user = User.first( :id => desc['user'] )

			rdebug "Event/to_hash desc"
			pp desc
			pp user

			res_desc = {
				:user => user.to_hash,
			  :zone => board[desc['zone']].to_desc_hash
			}
			res = {
				:id => self.id,
				:type => self.type,
				:desc => res_desc,
				:stamp => self.timestamp
			}
			return res
		end
	end

end

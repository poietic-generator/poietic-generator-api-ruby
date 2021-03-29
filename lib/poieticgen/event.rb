
require 'dm-core'
require 'json'

module PoieticGen
	class Event
		include DataMapper::Resource

		property :id,	Serial
		property :type,	String, required: true

		belongs_to :timeline, key: true
		belongs_to :user

		def self.create_join user, board
			Event.create({
				type: 'join',
				user: user,
				timeline: (Timeline.create_now board)
			})
		end

		def self.create_leave user, board
			Event.create({
				type: 'leave',
				user: user,
				timeline: (Timeline.create_now board)
			})
		end

		def to_hash ref
			res_desc = {
				user: self.user.to_hash,
				zone: (self.user.zone.to_desc_hash Zone::DESCRIPTION_MINIMAL)
			}

			res = {
				id: self.timeline.id,
				type: self.type,
				desc: res_desc,
				diffstamp: self.timeline.timestamp - ref
			}
			return res
		end

	end
end

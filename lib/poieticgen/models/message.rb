
require 'dm-core'
require 'json'

module PoieticGen
	class Message
		include DataMapper::Resource

		property :id,	Serial
		property :user_src,	Integer, required: true
		property :user_dst,	Integer, required: true
		property :content,	Text, required: true

		belongs_to :timeline, key: true

		def to_hash
			res = {
				id: self.timeline.id,
				user_src: self.user_src,
				user_dst: self.user_dst,
				content: self.content,
				stamp: self.timeline.timestamp
			}
			return res
		end

		def self.post src, dst, content, board
			create({
				user_src: src,
				user_dst: dst,
				content: content,
				timeline: (Timeline.create_now board)
			})
		end
	end

end

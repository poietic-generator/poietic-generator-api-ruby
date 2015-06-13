
require 'dm-core'
require 'json'

module PoieticGen
	class Event
		include DataMapper::Resource

		# @debug = true

		property :id,	Serial
		property :type,	String, :required => true

		belongs_to :timeline, :key => true
		belongs_to :user

		def self.create_join user, board
			begin
				event = Event.create({
					:type => 'join',
					:user => user,
					:timeline => (Timeline.create_now board)
				})
			rescue DataMapper::SaveFailureError => e
				pp "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
			
		end

		def self.create_leave user, board
			begin
				event = Event.create({
					:type => 'leave',
					:user => user,
					:timeline => (Timeline.create_now board)
				})
			rescue DataMapper::SaveFailureError => e
				rdebug "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
		def to_hash ref
			res_desc = {
				:user => self.user.to_hash,
				:zone => (self.user.zone.to_desc_hash Zone::DESCRIPTION_MINIMAL)
			}

			res = {
				:id => self.timeline.id,
				:type => self.type,
				:desc => res_desc,
				:diffstamp => self.timeline.timestamp - ref
			}
			return res
		end
		
	end

end

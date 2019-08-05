
require 'poieticgen'

module PoieticGen

	class User

		include DataMapper::Resource

		# This constant is the one used to check the leaved user, and generate
		# events. This check is made in the update_data method. It will be done
		# at least every LEAVE_CHECK_TIME_MIN days at a user update_data request.
		LEAVE_CHECK_TIMEOUT = 60

		property :id,	Serial
		property :token, String, required: true, unique: true, index: true
		property :name,	String, required: true
		property :created_at, Integer, required: true
		property :alive_expires_at, Integer, required: true, index: true
		property :idle_expires_at, Integer, required: true, index: true
		property :did_expire, Boolean, required: true, default: false, index: true
		property :last_update_time, Integer, required: true
		
		belongs_to :board
		has 1, :zone
		
		def initialize name, board, config
			now = Time.now

			super({
				board: board,
				token: (0...32).map{ ('a'..'z').to_a[rand(26)] }.join,
				name: name,
				zone: nil,
				created_at: now.to_i,
				alive_expires_at: (now + config.liveness_timeout).to_i,
				idle_expires_at: (now + config.idle_timeout).to_i,
				last_update_time: now
			})
		end

		def expired?
			now = Time.now.to_i
			return (self.did_expire or
				now >= self.alive_expires_at or
				now >= self.idle_expires_at)
		end

		def set_expired
			now = Time.now.to_i
			if self.alive_expires_at > now then
				self.alive_expires_at = now
			end
			if self.idle_expires_at > now then
				self.idle_expires_at = now
			end
			self.did_expire = true
		end

		def to_hash
			res = {
				:id => self.id,
				:name => self.name,
				:zone => self.zone.index
			}
			return res
		end

		def self.from_token user_config, token, name, board
			user = User.first(:token => token)
			if user.nil? or user.expired? then
				# No user matching conditions, creating new user
				user = User.new name, board, user_config
			end
			return user
		end

		def self.canonical_username req_name
			if req_name.nil? or (req_name.length == 0) then
				return "anonymous"
			else
				return req_name
			end
		end

		def self.check_expired_users
			now = Time.now.to_i

      User.transaction do 
        last_check = 
          Meta.first(name: 'user_gc_last') ||
          Meta.create(name: 'user_gc_last', value: now.to_s) 

			  # remove expired users that have not yet been declared as expired
			  if (last_check.value.to_i + LEAVE_CHECK_TIMEOUT) < now then
				  newly_expired_users = 
				    User.all(did_expire: false,	:alive_expires_at.lte => now) + 
				    User.all(did_expire: false,	:idle_expires_at.lte => now)

				  newly_expired_users.each do |leaver|
				    leaver.set_expired
				    leaver.board.leave leaver
				    leaver.save
				  end
				  last_check.value = now.to_s
				  last_check.save
			  end
      end
		end
	end

end

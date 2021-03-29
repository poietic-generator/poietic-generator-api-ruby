
require 'poieticgen'

module PoieticGen

	class Admin

		include DataMapper::Resource

		property :id,	Serial
		property :token, String, :required => true, :unique => true
		property :name,	String, :required => true
		property :created_at, Integer, :required => true
		property :expires_at, Integer, :required => true
		property :did_expire, Boolean, :required => true, :default => false
		property :last_update_time, Integer, :required => true
		
		# @debug = true

		def self.create name, config
			now = Time.now

			super({
				:token => (0...32).map{ ('a'..'z').to_a[rand(26)] }.join,
				:name => name,
				:created_at => now.to_i,
				:expires_at => (now + config.idle_timeout).to_i,
				:last_update_time => now
			})
		end


		def expired?
			now = Time.now.to_i
			return (self.did_expire or
				now >= self.expires_at)
		end


		def set_expired
			now = Time.now.to_i
			if self.expires_at > now then
				self.expires_at = now
			end
			self.did_expire = true
			self.save
		end


		def report_expiration config
			self.expires_at = (Time.now + config.idle_timeout).to_i
			self.did_expire = false
			self.save
		end
	end

end

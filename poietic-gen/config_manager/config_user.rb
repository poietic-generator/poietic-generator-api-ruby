
module PoeticGen ; class ConfigManager

	class ConfigUser
		attr_reader :max_clients
		attr_reader :max_idle
		attr_reader :keepalive

		def initialize hash
			raise MissingField,"User.max_clients" unless hash.include? "max_clients"
			@max_clients = ConfigManager.parse_int hash["max_clients"], "User.max_clients"

			raise MissingField, "User.max_idle" unless hash.include? "max_idle"
			@max_idle = ConfigManager.parse_int hash["max_idle"], "User.max_idle"

			raise MissingField, "User.keepalive" unless hash.include? "keepalive"
			@keepalive = ConfigManager.parse_int hash["keepalive"], "User.keepalive"
		end
	end

end ; end

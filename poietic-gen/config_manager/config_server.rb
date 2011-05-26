
module PoieticGen ; class ConfigManager

	class ConfigServer
		attr_reader :ssl
		attr_reader :virtualhost
		attr_reader :root_url
		attr_reader :port

		def initialize hash
			raise MissingField, "Server.ssl" unless hash.include? "ssl"
			@ssl = ConfigManager.parse_bool hash["ssl"], "Server.ssl"
			raise MissingField, "Server.virtualhost" unless hash.include? "virtualhost"
			@virtualhost = hash["virtualhost"]
			raise MissingField, "Server.root" unless hash.include? "root"
			@root = hash["root"]
			raise MissingField, "Server.port" unless hash.include? "port"
			@port = ConfigManager.parse_int hash["port"], "Server.port"
		end
	end

end ; end

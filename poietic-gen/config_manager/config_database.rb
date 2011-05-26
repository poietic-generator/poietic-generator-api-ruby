
module PoieticGen ; class ConfigManager

	class ConfigDatabase

		class UnknownAdapter < RuntimeError ; end

		attr_reader :adapter
		attr_reader :host
		attr_reader :username
		attr_reader :password
		attr_reader :database

		def initialize hash
			raise MissingField, "database.adapter" unless hash.include? "adapter"
			case hash["adapter"].strip.downcase
			when "sqlite" then
				@adapter = 'sqlite'
				raise MissingField, "database.database" unless hash.include? "database"
				@database = hash["database"]
				@host = nil
				@username = nil
				@password = nil
			when "mysql" then
				raise MissingField, "database.host" unless hash.include? "host"
				@host = hash["host"]
				raise MissingField, "database.username" unless hash.include? "username"
				@username = hash["username"]
				raise MissingField, "database.password" unless hash.include? "password"
				@password = hash["password"]
				raise MissingField, "database.database" unless hash.include? "database"
				@database = hash["database"]
			else raise BadFieldType, "database.adapter must be [sqlite|mysql]"
			end
		end

		def get_hash
			case @adapter
			when 'sqlite' then
				return {
					"adapter"   => 'sqlite3',
					"database"  => @database,
					"username"  => "",
					"password"  => "",
					"host"      => ""
				}
			when 'mysql' then
				return {
					"adapter"   => 'mysql',
					"database"  => @database,
					"username"  => @username,
					"password"  => @password,
					"host"      => @host
				}
			end
		end

		def get_url
			case @adapter
			when 'sqlite' then
				return "sqlite3://%s" % @database
			when 'mysql' then
				return "mysql://%s:%s@%s/%s" % @username, @password, @host, @database
			else
				raise UnknownAdapter, @adapter
			end
		end
	end

end ; end

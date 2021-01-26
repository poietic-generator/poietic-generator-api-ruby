##############################################################################
#                                                                            #
#  Poietic Generator Reloaded is a multiplayer and collaborative art         #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011-2013 - Gnuside                                         #
#                                                                            #
#  This program is free software: you can redistribute it and/or modify it   #
#  under the terms of the GNU Affero General Public License as published by  #
#  the Free Software Foundation, either version 3 of the License, or (at     #
#  your option) any later version.                                           #
#                                                                            #
#  This program is distributed in the hope that it will be useful, but       #
#  WITHOUT ANY WARRANTY; without even the implied warranty of                #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero  #
#  General Public License for more details.                                  #
#                                                                            #
#  You should have received a copy of the GNU Affero General Public License  #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.     #
#                                                                            #
##############################################################################

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
			when 'sqlite' then
				@adapter = 'sqlite'
				raise MissingField, "database.database" unless hash.include? "database"
				@database = hash["database"]
				@host = nil
				@username = nil
				@password = nil
			when 'postgres' then
				@adapter = 'postgres'
				raise MissingField, "database.host" unless hash.include? "host"
				@host = hash["host"]
				raise MissingField, "database.username" unless hash.include? "username"
				@username = hash["username"]
				raise MissingField, "database.password" unless hash.include? "password"
				@password = hash["password"]
				raise MissingField, "database.database" unless hash.include? "database"
				@database = hash["database"]
			when 'mysql' then
				@adapter = 'mysql'
				raise MissingField, "database.host" unless hash.include? "host"
				@host = hash["host"]
				raise MissingField, "database.username" unless hash.include? "username"
				@username = hash["username"]
				raise MissingField, "database.password" unless hash.include? "password"
				@password = hash["password"]
				raise MissingField, "database.database" unless hash.include? "database"
				@database = hash["database"]
			else raise BadFieldType, "database.adapter must be [sqlite|mysql|postgres]"
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
					"host"      => "",
					"timeout" 	=> 15000
				}
			when 'postgres' then
				return {
					"adapter"   => 'postgres',
					"database"  => @database,
					"username"  => @username,
					"password"  => @password,
					"host"      => @host
				}
			when 'mysql' then
				return {
					"adapter"   => 'mysql',
					"database"  => @database,
					"username"  => @username,
					"password"  => @password,
					"host"      => @host
				}
			else
				raise UnknownAdapter, @adapter
			end
		end

		def get_url
			case @adapter
			when 'sqlite' then
				return "sqlite3://%s" % @database
			when 'mysql' then
				return "mysql://%s:%s@%s/%s" % @username, @password, @host, @database
			when 'postgres' then
				return "postgres://%s:%s@%s/%s" % @username, @password, @host, @database
			else
				raise UnknownAdapter, @adapter
			end
		end
	end

end ; end

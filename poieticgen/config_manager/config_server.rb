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

	class ConfigServer
		attr_reader :ssl
		attr_reader :virtualhost
		attr_reader :root_url
		attr_reader :port
		attr_reader :pidfile

		def initialize hash
			raise MissingField, "Server.ssl" unless hash.include? "ssl"
			@ssl = ConfigManager.parse_bool hash["ssl"], "Server.ssl"
			raise MissingField, "Server.virtualhost" unless hash.include? "virtualhost"
			@virtualhost = hash["virtualhost"]
			raise MissingField, "Server.root" unless hash.include? "root"
			@root = hash["root"]
			raise MissingField, "Server.port" unless hash.include? "port"
			@port = ConfigManager.parse_int hash["port"], "Server.port"
			raise MissingField, "Server.pidfile" unless hash.include? "pidfile"
			@pidfile = hash["pidfile"]
		end
	end

end ; end

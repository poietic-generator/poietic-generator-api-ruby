##############################################################################
#                                                                            #
#  Poetic Generator Reloaded is a multiplayer and collaborative art          #
#  experience.                                                               #
#                                                                            #
#  Copyright (C) 2011 - Gnuside                                              #
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

require 'inifile'

module PoieticGen

	class ConfigManager
		attr_reader :server
		attr_reader :chat
		attr_reader :database
		attr_reader :user
		attr_reader :board

		DEFAULT_CONFIG_PATH = File.expand_path( File.join File.dirname(__FILE__), "../config/config.ini" )

		class ConfigurationError < RuntimeError ; end

		# Exception raised when a configuration file is missing
		class MissingFile < ConfigurationError ; end

		# Exception raised when a section is missing.
		class MissingSection < ConfigurationError ; end

		# Exception raised when a field is missing in a section.
		class MissingField < ConfigurationError ; end

		# Exception raised when a field has a bad type.
		class BadFieldType < ConfigurationError ; end


		#
		#
		#
		def self.parse_bool str, err_msg
			case str.strip.downcase
			when /^(yes|true)$/ then return true
			when /^(no|false)$/ then return true
			else raise BadFieldType, (err_msg + " must be [yes|true|no|false]")
			end
		end


		#
		#
		#
		def self.parse_int str, err_msg
			case str
			when /^(\d+)$/ then return $1.to_i
			else raise BadFieldType, (err_msg + " must be an integer")
			end
		end



		#
		#
		#
		def initialize conf_file
			puts "PoieticGen::ConfigManager - initialize with file : '%s'\n" % conf_file
			unless File.exist? conf_file then
				raise MissingFile, "Configuration file %s not found" % conf_file
			end

			ini_fh = IniFile.load conf_file
			raise MissingSection unless ini_fh.has_section? "server"
			@server = ConfigServer.new ini_fh["server"]

			raise MissingSection, "board" unless ini_fh.has_section? "board"
			@board = ConfigBoard.new ini_fh["board"]

			raise MissingSection, "database" unless ini_fh.has_section? "database"
			@database = ConfigDatabase.new ini_fh["database"]

			raise MissingSection, "chat" unless ini_fh.has_section? "chat"
			@chat = ConfigChat.new ini_fh["chat"]

			raise MissingSection, "user" unless ini_fh.has_section? "user"
			@user = ConfigUser.new ini_fh["user"]
		end

	end

end

require 'poieticgen/config_manager/config_server'
require 'poieticgen/config_manager/config_chat'
require 'poieticgen/config_manager/config_user'
require 'poieticgen/config_manager/config_board'
require 'poieticgen/config_manager/config_database'


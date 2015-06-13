
require 'inifile'

module PoieticGen

	class ConfigManager
		attr_reader :server
		attr_reader :chat
		attr_reader :database
		attr_reader :user
		attr_reader :board

		DEFAULT_CONFIG_PATH = File.join "config", "config.ini"

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
			#STDERR.puts "parsing str [#{str}]"
			case str
			when FalseClass then return false
			when TrueClass then return true
			else
				case str.to_s.strip.downcase
				when /^(yes|true)$/ then return true
				when /^(no|false)$/ then return true
				else raise BadFieldType, (err_msg + " must be [yes|true|no|false]")
				end
			end
		end


		#
		#
		#
		def self.parse_int str, err_msg
			#STDERR.puts "parsing str [#{str}] of #{str.class}"
			case str
			when Fixnum then return str
			else
				case str
				when /^(\d+)$/ then return $1.to_i
				else raise BadFieldType, (err_msg + " must be an integer")
				end
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


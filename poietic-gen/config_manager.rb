
require 'inifile'

module PoieticGen

	class ConfigManager
		attr_reader :server
		attr_reader :chat
		attr_reader :database
		attr_reader :user
		attr_reader :board

		DEFAULT_CONFIG_PATH = File.expand_path( File.join File.dirname(__FILE__), "../config.ini" )

		# Exception raised when a section is missing.
		class MissingSection < RuntimeError ; end

		# Exception raised when a field is missing in a section.
		class MissingField < RuntimeError ; end

		# Exception raised when a field has a bad type.
		class BadFieldType < RuntimeError ; end


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

require 'poietic-gen/config_manager/config_server'
require 'poietic-gen/config_manager/config_chat'
require 'poietic-gen/config_manager/config_user'
require 'poietic-gen/config_manager/config_board'
require 'poietic-gen/config_manager/config_database'


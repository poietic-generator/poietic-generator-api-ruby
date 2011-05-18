
require 'inifile'

module PoeticGen

	class ServerConfig

		DEFAULT_CONFIG_PATH = File.expand_path( File.join File.dirname(__FILE__), "../poietic-gen.ini" )

		# An exception for invalid configurations files
		class InvalidConfiguration < RuntimeError ; end

		# An exception for invalid content
		class InvalidContent < TypeError ; end


		# FIXME: declare some getters/setters

		def initialize filename
			# FIXME: initialize attributes
		end

		#
		# load filename 
		#
		def load filename
		end

		#
		# validate current configuration
		#
		def validate!
		end
	end

	class Config_server

		attr_reader :use_ssl
		attr_reader  :virtualhost
		attr_reader :root_url
		attr_reader :port
		attr_reader :max_clients
		attr_reader :max_idle_time

		def initialize use_ssl, virtualhost, root_url,
			port, max_clients, max_idle_time

			# TODO : check variable type and content validity.
			@use_ssl = use_ssl
			@virtualhost = virtualhost
			@root_url = root_url
			@port = port
			@max_clients = max_clients
			@max_idle_time = max_idle_time
		end
	end

	class Config_zone
		attr_reader :zone_name
		attr_reader :allocator
		attr_reader :colors
		attr_reader :width 
		attr_reader :height

		def initialize zone_name, allocator, colors, width, height
			# TODO : check variable type and content validity
			@zone_name = zone_name
			@allocator = allocator
			@colors = colors
			@width = width
			@height = height
		end
	end


	class Config_manager
		attr_reader :server_config

		def initialize conf_file
			@server_config = Config_server.new(false,
										 "www.example.com",
										 "/", 8000, 1000, 300)
			@zones_cfg = [Config_zone.new("example",
										  "spiral", # TODO replace by ruby module
										  "ansi", # TODO replace by ruby module
										  16, 16)]
		end

		def server_cfg
			return @server_config
		end

		def nb_zones
			return @zones_cfg.length
		end

		def get_zone i
			if i < @zones_cfg.length then
				return @zones_cfg[i]
			else
				return nil
			end
		end
	end

end

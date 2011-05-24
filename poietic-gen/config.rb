
require 'inifile'

module PoieticGen

  class ConfigManager
    attr_reader :server_cfg
    attr_reader :chat_cfg
    attr_reader :database_cfg
    attr_reader :user_cfg
    attr_reader :board_cfg

    DEFAULT_CONFIG_PATH = File.expand_path( File.join File.dirname(__FILE__), "../poietic-gen.ini" )

    # Exception raised when a section is missing.
    class MissingSection < RuntimeError ; end

    # Exception raised when a field is missing in a section.
    class MissingField < RuntimeError ; end

    # Exception raised when a field has a bad type.
    class BadFieldType < RuntimeError ; end

    def self.parse_bool str, err_msg
      case str.strip.downcase
      when /^(yes|true)$/ then return true
      when /^(no|false)$/ then return true
      else raise BadFieldType, (err_msg + " must be [yes|true|no|false]")
      end
    end

    def self.parse_int str, err_msg
      case str
      when /^(\d+)$/ then return $1.to_i
      else raise BadFieldType, (err_msg+ " must be an integer")
      end
    end

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

    class ConfigBoard
      attr_reader :name
      attr_reader :allocator
      attr_reader :colors
      attr_reader :width
      attr_reader :height

      def initialize hash
        raise MissingField, "Board.name" unless hash.include? "name"
        @name = hash["name"]
        raise MissingField, "Board.allocator" unless hash.include? "allocator"
        case hash["allocator"].strip.downcase
        when /^spiral$/ then @allocator = "spiral"
        when /^random$/ then @allocator = "random"
        else raise BadFieldType, "Board.adapter must be [spiral|random]"
        end
        raise MissingField, "Board.colors" unless hash.include? "colors"
        case hash["colors"].strip.downcase
        when /^ansi$/ then @colors = "ansi"
        when /^truecolor$/ then @colors = "truecolor"
        else raise BadFieldType, "Board.color must be [ansi|truecolor]"
        end
        raise MissingField, "Board.width" unless hash.include? "width"
        @width = ConfigManager.parse_int hash["width"], "Board.width"
        raise MissingField, "Board.height" unless hash.include? "height"
        @height = ConfigManager.parse_int hash["height"], "Board.height"
      end
    end

    class ConfigDatabase
      attr_reader :adapter
      attr_reader :host
      attr_reader :username
      attr_reader :password
      attr_reader :database

      def initialize hash
        raise MissingField, "database.adapter" unless hash.include? "adapter"
        case hash["adapter"].strip.downcase
        when /^(sqlite|mysql)$/ then @adapter = $1
        else raise BadFieldType, "database.adapter must be [sqlite|mysql]"
        end
        raise MissingField, "database.host" unless hash.include? "host"
        @host = hash["host"]
        raise MissingField, "database.username" unless hash.include? "username"
        @username = hash["username"]
        raise MissingField, "database.password" unless hash.include? "password"
        @password = hash["password"]
        raise MissingField, "database.database" unless hash.include? "database"
        @database = hash["database"]
      end
    end

    class ConfigChat
      attr_reader :enable

      def initialize hash
        raise MissingField, "Chat.enable" unless hash.include? "enable"
        @enable = ConfigManager.parse_bool hash["enable"], "Chat.enable"
      end
    end

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

    def initialize conf_file
      inif = IniFile.load conf_file
      raise MissingSection unless inif.has_section? "server"
      @server_config = ConfigServer.new inif["server"]
      raise MissingSection, "board" unless inif.has_section? "board"
      @board_cfg = ConfigBoard.new inif["board"]
      raise MissingSection, "database" unless inif.has_section? "database"
      @database_cfg = ConfigDatabase.new inif["database"]
      raise MissingSection, "chat" unless inif.has_section? "chat"
      @chat_cfg = ConfigChat.new inif["chat"]
      raise MissingSection, "user" unless inif.has_section? "user"
      @user_cfg = ConfigUser.new inif["user"]
    end

  end

end


module Config

  class Config_server
    attr_reader :use_ssl, :virtualhost, :root_url,
      :port, :max_clients, :max_idle_time
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
    attr_reader :zone_name, :allocator, :colors, :width, :height
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
    def initialize conf_file
      @srv_cfg = Config_server.new(false,
                                   "www.example.com",
                                   "/", 8000, 1000, 300)
      @zones_cfg = [Config_zone.new("example",
                                    "spiral", # TODO replace by ruby module
                                    "ansi", # TODO replace by ruby module
                                    16, 16)]
    end

    def get_server_cfg
      return @srv_cfg
    end

    def get_nb_zones
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

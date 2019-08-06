# -*- coding: utf-8 -*-

require 'poieticgen'

module PoieticGen
  class DatabaseConnectionError < RuntimeError ; end

  class Api < Sinatra::Base
    register Sinatra::Namespace

    STATUS_INFORMATION  = 1
    STATUS_SUCCESS      = 2
    STATUS_REDIRECTION  = 3
    STATUS_SERVER_ERROR = 4
    STATUS_BAD_REQUEST  = 5

    enable :run

    set :root, File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
    set :environment, :production

    set :static, false
    set :protection, except: :frame_options

    configure do
      begin
        config_path = File.join(settings.root,PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH)
        config = PoieticGen::ConfigManager.new(config_path)

        FileUtils.mkdir_p File.dirname config.server.pidfile
        File.write(config.server.pidfile, Process.pid)

        set :config, config

        DataMapper.finalize
        DataMapper::Logger.new(STDERR, :info)
        # DataMapper::Logger.new(STDERR, :debug)
        hash = config.database.get_hash
        DataMapper.setup(:default, hash)

        # raise exception on save failure (globally across all models)
        DataMapper::Model.raise_on_save_failure = true
        DataMapper.auto_upgrade!

        manager = PoieticGen::Manager.new(config)
        set :manager, manager
        set :controllers, {}

      rescue ::DataObjects::SQLError => e
        STDERR.puts "ERROR: Unable to connect to database."
        STDERR.puts "\t Verify your settings in config.ini and try again."
        STDERR.puts ""
        STDERR.puts "%s" % e.message
        exit 1

      rescue PoieticGen::ConfigManager::ConfigurationError => e
        STDERR.puts "ERROR: %s" % e.message
        exit 1
      end
    end

    namespace '/user' do
      register AuthenticationsRoutes
      register RegistrationsRoutes

    end

    namespace '/spaces' do
      register SpacesRoutes

      # get { SpacesController.index }
      # post { SpacesController.create }

      namespace '/:space_id/sessions' do
        get { SessionsController.index }
        post { SessionsController.create }
      end
    end

    get '/' do
      text = <<-MARK
      Welcome to Poetic Generator API v2.

      Please read documentation for more information.
      MARK
      text.split(/\n/).map(&:strip).join("\n")
    end

  end
end


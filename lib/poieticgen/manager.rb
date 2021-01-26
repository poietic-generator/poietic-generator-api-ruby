# frozen_string_literal: true

require 'time'
require 'pp'


module PoieticGen
  class InvalidSession < RuntimeError; end
  class AdminSessionNeeded < RuntimeError; end

  #
  # manage a pool of users
  #
  class Manager
    attr_accessor :config

    def initialize(config)
      @config = config
      @chat = PoieticGen::ChatManager.new @config.chat
    end
  end
end

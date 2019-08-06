
require 'thread'
require 'time'
require 'pp'

require 'poieticgen/palette'
require 'poieticgen/admin'
require 'poieticgen/chat_manager'
require 'poieticgen/update_request'
require 'poieticgen/snapshot_request'
require 'poieticgen/update_view_request'
require 'poieticgen/join_request'
require 'poieticgen/transaction'

module PoieticGen

	class InvalidSession < RuntimeError ; end
	class AdminSessionNeeded < RuntimeError ; end

	#
	# manage a pool of users
	#
	class Manager

		def initialize config
			@config = config
			@chat = PoieticGen::ChatManager.new @config.chat
		end

	end
end

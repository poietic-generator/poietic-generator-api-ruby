#!/usr/bin/env ruby

require 'bundler/setup'

require 'thor'

$:.insert 0, '.'
require 'poieticgen/config_manager'

module PoieticGen
	module CLI
		class Session < Thor

			def configure
				config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
				DataMapper::Logger.new(STDERR, :info)
				#DataMapper::Logger.new(STDERR, :debug)
				hash = config.database.get_hash
				#pp "db hash :", hash
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true

				DataMapper.auto_upgrade!
			end

			desc "session list", "List all session"
			def list
				puts "FIXME: List all sessions" 
			end

			desc "session create", "Create a new session"
			def create
				puts "FIXME: Create A new session" 
			end

			desc "session delete ID", "Delete session ID"
			def delete cmd
			end
		end


		class CLI < Thor
			desc "session SUBCOMMAND ...ARGS", "manage sessions"
			subcommand "session", Session
		end
	end
end

# load libraries
# choose session
PoieticGen::CLI::Main.start(ARGV)

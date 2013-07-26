#!/usr/bin/env ruby

require 'bundler/setup'

require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-types'
require 'thor'
require 'pp'

$:.insert 0, '.'
require 'poieticgen/config_manager'
require 'poieticgen/session'

module PoieticGen
	module CLI
		class Session < Thor


			desc "list", "List all session"
			def list
				configure
				sessions = PoieticGen::Session.all	
				sessions.each do |s|
					puts "ID % 3d - TOKEN %s - [START %s .. STOP none]" % [ 
						s.id, s.token, 
						Time.at(s.timestamp).utc.iso8601
					]
				end

			end

			desc "start LABEL", "Start a new session"
			def create
				raise NotImplementedError
			end

			desc "rename ID NEWLABEL", "Rename a session"
			def rename id
				configure
				session = PoieticGen::Session.first(:id => id.to_i)
				pp session
			end

			desc "finish", "Finish a session"
			def finish
				puts "FIXME: Create A new session" 
				raise NotImplementedError
			end

			desc "delete ID", "Delete session ID"
			def delete id
				configure
				session = PoieticGen::Session.first(:id => id.to_i)
				if session.nil? then
					puts "ERROR: Session %s does not exist." % id.to_i
					exit 1
				end

				session.destroy
				pp session
			end

			desc "shapshot OFFSET", "Dump snapshot at OFFSET"
			def snapshot cmd
				raise NotImplementedError
			end


			private
			def configure
				@config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
				DataMapper::Logger.new(STDERR, :info)
				#DataMapper::Logger.new(STDERR, :debug)
				hash = @config.database.get_hash
				#pp "db hash :", hash
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true

				DataMapper.auto_upgrade!
			end
		end


		class Main < Thor
			desc "session SUBCOMMAND ...ARGS", "manage sessions"
			subcommand "session", Session
		end
	end
end

# load libraries
# choose session
PoieticGen::CLI::Main.start(ARGV)

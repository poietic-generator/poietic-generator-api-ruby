#!/usr/bin/env ruby

require 'bundler/setup'

require 'thor'

module PoieticGen


	class CLI < Thor
		class Session < Thor
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


		desc "session SUBCOMMAND ...ARGS", "manage sessions"
		subcommand "session", Session
	end
end

# load libraries
# choose session
PoieticGen::CLI.start(ARGV)

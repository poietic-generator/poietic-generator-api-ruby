#!/usr/bin/env ruby

require 'bundler/setup'

require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-constraints'
require 'dm-types'
require 'thor'
require 'rdebug/base'
require 'pp'

$:.insert 0, '.'
require 'bin/image'
require 'poieticgen/config_manager'
require 'poieticgen/board'

module PoieticGen
	module CLI
		class Session < Thor
			desc "list", "List all session"
			def list
				configure
				sessions = PoieticGen::Board.all
				sessions.each do |s|
					puts "ID % 3d - TOKEN %s - [START %s .. STOP none]" % [ 
						s.id, s.token, 
						Time.at(s.timestamp).utc.iso8601
					]
				end

			end

			desc "create", "Start a new session"
			def create
				configure
				# TODO: add a session name
				PoieticGen::Board.create @config.board
			end

			desc "rename ID NEWLABEL", "Rename a session"
			def rename id, new_label
				configure
				session = PoieticGen::Board.first(:id => id.to_i)
				pp session
				puts "FIXME: Rename a session"
			end

			desc "finish ID", "Finish a session"
			def finish id
				configure
				session = PoieticGen::Board.first(:id => id.to_i)
				session.close
				puts "FIXME: kill users and zones"
			end
 
			option :all, :type => :boolean, :aliases => :a
			desc "delete (-a | ID)", "Delete session ID"
			def delete id=nil
				configure
				if options[:all] then
					sessions = PoieticGen::Board.all
					res = sessions.destroy
				else
					session = PoieticGen::Board.first(:id => id.to_i)
					if session.nil? then
						puts "ERROR: Session %s does not exist." % id.to_i
						exit 1
					end
					pp session.users
					pp session
					res = session.destroy
					pp res
				end
			end

			desc "shapshot ID OFFSET FILENAME [FACTOR]", "Dump snapshot in session ID at OFFSET and save it in FILENAME"
			def snapshot id, offset, filename, factor=1
				configure
				board = PoieticGen::Board.first(:id => id.to_i)

				if board.nil? then
					puts "The board %s does not exist" % id
					return
				end

				# FIXME: when not closed, remove ~30 seconds from finish
				offset = offset.to_i
				timestamp = board.timestamp + offset
				end_timestamp = if board.closed then board.end_timestamp else Time.now.to_i end

				if offset < 0 or timestamp > end_timestamp then
					puts "Offset '%d' out of bounds (%d -> %d)" %
						[ offset, 0, (end_timestamp - board.timestamp) ]
					return
				end

				zones = board.load_board timestamp

				width, height, diff_x, diff_y = board.max_size

				factor = factor.to_i
				black = PoieticGen::CLI::Color.from_rgb(0, 0, 0)
				image = PoieticGen::CLI::Image.new width * factor, height * factor, black

				pp "board width=%d, height=%d, x=%d, y=%d" % [ width, height, diff_x, diff_y ]

				zones.each do |index, zone|
					zone_x, zone_y = zone.position
					zone_x = (zone_x * zone.width) - diff_x
					zone_y = (zone_y * zone.height) - diff_y

					pp "zone %d width=%d, height=%d, x=%d, y=%d" %
						[ index, zone.width, zone.height, zone_x, zone_y ]

					(0..zone.height-1).each do |y|
						(0..zone.width-1).each do |x|
							color = PoieticGen::CLI::Color.from_hex (zone.color x, y)
							image.draw_rect (zone_x + x) * factor,
								(zone_y + y) * factor,
								factor, factor, color
						end
					end
				end

				image.save filename
			end
			
			desc "range ID", "Duration of session ID"
			def range id
				configure
				board = PoieticGen::Board.first(:id => id.to_i)
				
				# FIXME: when not closed, remove ~30 seconds from finish
				start = board.timestamp
				finish = if board.closed then board.end_timestamp else Time.now.to_i end
				
				puts "%d" % (finish - start)
			end


			private
			def configure
				$stdout = File.new '/dev/null', 'w' # mute STDOUT

				@config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
				DataMapper::Logger.new(STDERR, :info)
				#DataMapper::Logger.new(STDERR, :debug)
				hash = @config.database.get_hash
				#pp "db hash :", hash
				DataMapper.setup(:default, hash)

				# raise exception on save failure (globally across all models)
				DataMapper::Model.raise_on_save_failure = true

				DataMapper.auto_upgrade!

				$stdout = STDOUT # unmute STDOUT
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

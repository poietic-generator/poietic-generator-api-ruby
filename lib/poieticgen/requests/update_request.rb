
require 'optparse'

module PoieticGen
	class UpdateRequestParseError < OptionParser::ParseError ; end

	class UpdateRequest

		MESSAGES = 'messages'
		STROKES = 'strokes'

		TIMELINE_AFTER = 'timeline_after'

		TIMELINE_BEFORE = 'timeline_before'

		MESSAGES_DST = 'user_dst'
		MESSAGES_CONTENT = 'content'
		MESSAGES_STAMP = 'stamp'

		UPDATE_INTERVAL = 'update_interval'
		
		USER_TOKEN = 'user_token'

		SESSION_TOKEN = 'session_token'
		SINATRA_SPLAT = 'splat'
		SINATRA_CAPTURES = 'captures'

		private

		def initialize hash
			@hash = hash
			@enable_timeline = false # FIXME: unused
			# @debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when TIMELINE_AFTER then
					@enable_timeline = true
				when TIMELINE_BEFORE then
					@enable_timeline = true
				when MESSAGES then
					if val.length != 0 then
						rdebug "messages : %s" % val.inspect
          				end
				when STROKES then
				  	if val.length != 0 then
						rdebug "strokes : %s" % val.inspect
         				end
				when UPDATE_INTERVAL then
				  	begin
				    		rdebug "update_interval : %d" % val.to_i
				  	rescue Exception => e
				    		rdebug e
				    		raise UpdateRequestParseError, ("%s with invalid value : " % UPDATE_INTERVAL)
					end
				when USER_TOKEN then
					rdebug "user_token : %s" % val.inspect
				when SESSION_TOKEN then
					rdebug "session_token : %s" % val.inspect
				when SINATRA_SPLAT then
					rdebug "sinatra splat : %s" % val.inspect
				when SINATRA_CAPTURES then
					rdebug "sinatra captures : %s" % val.inspect
				else
					raise UpdateRequestParseError, "Unknow request field '%s'" % key
				end
			end

			[
				TIMELINE_AFTER,
				STROKES,
				MESSAGES,
				UPDATE_INTERVAL,
				USER_TOKEN,
				SESSION_TOKEN
			].each do |field|
				unless hash.include? field then
					raise UpdateRequestParseError, ("The '%s' field is missing" % field)
				end
			end
			# parse per-field content
			#
			hash[MESSAGES].each do |msg|
				[ 	MESSAGES_DST,
					MESSAGES_CONTENT,
					MESSAGES_STAMP
				].each do |field|
					unless msg.include? field then
						raise UpdateRequestParseError, ("The '%s' sub-field is missing" % field)
					end
				end
				# FIXME: msg[MESSAGES_DST].to_i
			end
			UpdateRequest.new hash
		end


		def strokes
			return @hash[STROKES]
		end

		def messages
			return @hash[MESSAGES]
		end

		def timeline_after
			return @hash[TIMELINE_AFTER].to_i
		end

		def update_interval
			return @hash[UPDATE_INTERVAL].to_i
    		end

    		def user_token
			return @hash[USER_TOKEN]
		end

    		def session_token
			return @hash[SESSION_TOKEN]
		end
	end
end


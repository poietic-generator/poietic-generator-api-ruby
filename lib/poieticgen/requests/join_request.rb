
require 'optparse'

module PoieticGen
	class JoinRequestParseError < OptionParser::ParseError ; end

	class JoinRequest

		USER_TOKEN = 'user_token'
		SESSION_TOKEN = 'session_token'
		USER_NAME = 'user_name'

		SINATRA_SPLAT = 'splat'
		SINATRA_CAPTURES = 'captures'

		private

		def initialize hash
			@hash = hash
			# @debug = true
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key
				when USER_NAME then
				  	rdebug "user_name : %s" % val.inspect
				when USER_TOKEN then
				  	rdebug "user_token : %s" % val.inspect
				when SESSION_TOKEN then
					rdebug "session_token : %s" % val.inspect
				when SINATRA_SPLAT then
					rdebug "sinatra splat : %s" % val.inspect
				when SINATRA_CAPTURES then
					rdebug "sinatra captures : %s" % val.inspect
				else
					raise JoinRequestParseError, "Unknow request field '%s'" % key
				end
			end

			[
				SESSION_TOKEN
			].each do |field|
				unless hash.include? field then
					raise JoinRequestParseError, ("The '%s' field is missing" % field)
				end
			end

			JoinRequest.new hash
		end


		def user_token
			return @hash[USER_TOKEN]
		end

		def user_name
			return @hash[USER_NAME]
		end
    		
    		def session_token
			return @hash[SESSION_TOKEN]
		end

	end
end



require 'optparse'

module PoieticGen
	class SnapshotRequestParseError < OptionParser::ParseError ; end

	class SnapshotRequest

		DATE = 'date'
		ID = 'id'
		
		SESSION_TOKEN = 'session_token'
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
				when DATE then
					rdebug "date : %s" % val.inspect
				when ID then
					rdebug "id : %s" % val.inspect
				when SESSION_TOKEN then
					rdebug "session : %s" % val.inspect
				when SINATRA_SPLAT then
					rdebug "sinatra splat : %s" % val.inspect
				when SINATRA_CAPTURES then
					rdebug "sinatra captures : %s" % val.inspect
				else
					raise SnapshotRequestParseError, "Unknow request field '%s'" % key
				end
			end

			[
				DATE,
				ID,
				SESSION_TOKEN
			].each do |field|
				unless hash.include? field then
					raise SnapshotRequestParseError, ("The '%s' field is missing" % field)
				end
			end
			SnapshotRequest.new hash
		end


		def date
			return @hash[DATE].to_i
		end
		
		def id
			return @hash[ID].to_i
		end

		def session_token
			return @hash[SESSION_TOKEN]
		end
	end

end


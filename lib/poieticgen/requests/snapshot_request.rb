
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
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			allowed_fields = [DATE, ID, SESSION_TOKEN, SINATRA_SPLAT, SINATRA_CAPTURES]

			hash.each do |key, val|
			  puts "%s : %s" % [key, val.inspect]
        unless allowed_fields.include? key then
          raise SnapshotRequestParseError, "Unknow request field '%s'" % key
        end
      end

			[DATE, ID, SESSION_TOKEN].each do |field|
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



module PoieticGen
	class UpdateRequest

		MESSAGES = 'messages'
		STROKES = 'strokes'

		MESSAGES_AFTER = 'messages_after'
		STROKES_AFTER = 'strokes_after'
		EVENTS_AFTER = 'events_after'

		MESSAGES_BEFORE = 'messages_before'
		STROKES_BEFORE = 'strokes_before'
		EVENTS_BEFORE = 'events_before'

		MESSAGES_DST = 'user_dst'
		MESSAGES_CONTENT = 'content'
		MESSAGES_STAMP = 'stamp'

		private

		def initialize hash
			@hash = hash
			@enable_strokes = false
			@enable_events = false
			@enable_messages = false
		end

		public

		def self.parse hash
			# mandatory fields firstvalidate user input first
			hash.each do |key, val|
				case key 
				when STROKES_AFTER then
					@enable_strokes = true
				when STROKES_BEFORE then
					@enable_strokes = true
				when MESSAGES_AFTER then
					@enable_messages = true
				when MESSAGES_BEFORE then
					@enable_messages = true
				when EVENTS_AFTER then
					@enable_events = true
				when EVENTS_BEFORE then
					@enable_events = true
				when MESSAGES then
					pp "messages", val	
				when STROKES then
					pp "strokes", val
				else
					raise RuntimeError, "unknow request field '%s'" % key
				end
			end

			[
				STROKES,
				MESSAGES
			].each do |field|
				unless hash.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
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
						raise ArgumentError, ("The '%s' sub-field is missing" % field)
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

		def messages_after
			return @hash[MESSAGES_AFTER].to_i
		end

		def strokes_after
			return @hash[STROKES_AFTER].to_i
		end

		def events_after
			return @hash[EVENTS_AFTER].to_i
		end

	end
end


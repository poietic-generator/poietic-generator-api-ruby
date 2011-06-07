
module PoieticGen
	class UpdateRequest

		CHAT = 'messages'
		DRAWING = 'strokes'

		CHAT_SINCE = 'messages_since'
		DRAWING_SINCE = 'strokes_since'
		EVENT_SINCE = 'events_since'

		private

		def initialize json
			@json = json	
		end

		public

		def self.parse json
			# mandatory fields firstvalidate user input first
			[	DRAWING_SINCE, 
				EVENT_SINCE, 
				CHAT_SINCE,
				DRAWING, 
				CHAT
			].each do |sym|
				unless json.include? sym.to_s then
					raise ArgumentError, ("The '%s' field is missing" % sym) 
				end
			end
			# parse per-field content
			#
			UpdateRequest.new json
		end


		def drawing
			return @json[DRAWING]
		end

		def chat 
			return @json[CHAT]
		end

		def messages_since
			return @json[CHAT_SINCE].to_i
		end

		def strokes_since
			return @json[DRAWING_SINCE].to_i
		end

		def events_since
			return @json[EVENT_SINCE].to_i
		end

	end
end


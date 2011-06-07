
module PoieticGen
	class UpdateRequest

		DRAWING_SINCE = 'event_since'
		EVENT_SINCE = 'event_since'
		CHAT_SINCE = 'chat_since'
		DRAWING = 'drawing'
		CHAT = 'chat'

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

		private
		def initialize json
			@json = json	
		end

		def drawing
			return json[DRAWING]
		end

		def chat 
			return json[CHAT]
		end

		def chat_since
			return json[CHAT_SINCE].to_i
		end

		def drawing_since
			return json[DRAWING_SINCE].to_i
		end

		def event_since
			return json[EVENT_SINCE].to_i
		end
	end
end



module PoieticGen
	class UpdateRequest

		CHAT = 'messages'
		DRAWING = 'strokes'

		CHAT_SINCE = 'messages_since'
		DRAWING_SINCE = 'strokes_since'
		EVENT_SINCE = 'events_since'

		CHAT_DST = 'user_dst'
		CHAT_CONTENT = 'content'
		CHAT_STAMP = 'stamp'

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
			].each do |field|
				unless json.include? field then
					raise ArgumentError, ("The '%s' field is missing" % field)
				end
			end
			# parse per-field content
			#
			json[CHAT].each do |msg|
				[ 	CHAT_DST,
					CHAT_CONTENT,
					CHAT_STAMP
				].each do |field|
					unless msg.include? field then
						raise ArgumentError, ("The '%s' sub-field is missing" % field)
					end
				end
				# FIXME: msg[CHAT_DST].to_i
			end
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


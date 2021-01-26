
require 'poieticgen'

module PoieticGen
	class BoardGroup
		include DataMapper::Resource

		property :id,	Serial
		property :name,          String,  unique: true, :required=> false
		property :token, String,  required: true, unique: true
		property :closed,        Boolean, default: false
		property :timestamp_start,     Integer, required: true
		property :timestamp_stop, Integer, default: 0
		property :allocator_type, String, required: true

		has n, :boards


    def current_board
    end

		def self.create(config, name)
			res = super({
				# FIXME: when the token already exists, SaveFailureError is raised
				token: (0...16).map{ ('a'..'z').to_a[rand(26)] }.join,
				timestamp_start: Time.now.to_i,
				allocator_type: config.allocator,
				name: name
			})

			@debug = true
			rdebug "using allocator %s" % config.allocator
			return res

		rescue DataMapper::SaveFailureError => e
			rdebug "Saving failure : %s" % e.resource.errors.inspect
			raise e
		end

		# if not, use the latest session
		def self.from_token token
			# FIXME: use a constant for latest session name
			if token == "latest" then
                BoardGroup.first(closed: false, 
								 order: [:id.desc])
            else
				BoardGroup.first(token: token,
								closed: false)
			end
		end

		def live?
			board = self.boards.first(closed: false,
							   order: [:timestamp.desc])
			return (not board.nil?)
		end

		# Get latest live board
		def board
			return self.boards.first(
			  closed: false,
				order: [:timestamp.desc]
			)
		end

		# Get latest live board or create one
		def create_board board_config
			board = self.board
			if board.nil? then
				board = Board.create board_config, self
				board.save
			end
			return board

		rescue DataMapper::SaveFailureError => e
			STDERR.puts e.resource.errors.inspect
			raise e
		end

		def canonical_name 
			return (if self.name.nil? then
				"Session %d" % self.id
			else
				self.name
			end)
		end

		def live_users_count
			return (self.live? ? self.board.live_users_count : 0 )
		end

		def to_h
		  {
		    name: self.name,
		    token: self.token,
		    closed: self.closed,
		    timestamp_start: self.timestamp_start,
		    timestamp_stop: self.timestamp_stop,
		    allocator_type: self.allocator_type
		  }
		end
	end
end


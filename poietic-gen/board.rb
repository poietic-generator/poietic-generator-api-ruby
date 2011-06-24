
require 'poietic-gen/update_request'
require 'poietic-gen/zone'
require 'poietic-gen/user'

require 'poietic-gen/allocation/spiral'
require 'poietic-gen/allocation/random'

require 'monitor'

module PoieticGen

	#
	# A class that manages the global drawing
	#
	class Board

		attr_reader :config

		ALLOCATORS = {
			"spiral" => PoieticGen::Allocation::Spiral,
			"random" => PoieticGen::Allocation::Random,
		}


		def initialize config
			@debug = true
			rdebug "using allocator %s" % config.allocator
			@config = config
			@allocator = ALLOCATORS[config.allocator].new config
			pp @allocator
			@monitor = Monitor.new
		end


		#
		# Get access to zone with given index
		#
		def [] idx
			return @allocator[idx]
		end

		#
		# make the user join the board
		#
		def join user
			@monitor.synchronize do
				zone = @allocator.allocate
				zone.user = user
				user.zone = zone.index
			end
		end

		#
		# disconnect user from the board
		#
		def leave user
			@monitor.synchronize do
				@allocator.free user.zone
			end
		end


		def update_data user, drawing
			@monitor.synchronize do
				zone = @allocator[user.zone]
				zone.apply user, drawing
			end
		end
	end

end


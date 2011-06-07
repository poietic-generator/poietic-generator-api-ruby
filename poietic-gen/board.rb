
require 'poietic-gen/zone'
require 'poietic-gen/user'

module PoieticGen

	#
	# A class that manages the global drawing
	#
	class Board

		attr_reader :config

		ALLOCATORS = {
			"spiral" => PoieticGen::Spiral,
			"random" => PoieticGen::Random,
			"generic" => PoieticGen::Generic
		}


		def initialize config
			@config = config
			@allocator = ALLOCATORS[config.allocator].new config
		end


		def join user
				zone = @allocator.allocate
				zone.user = user
				user.zone = zone.index
		end

		def leave user
		end


		def update_data user, data
			zone = @allocator[user.zone]
			.zone, data["drawing"]

			zone.apply data['drawing']
		end
	end

end



module PoieticGen
	class Zone

		attr_reader :index, :position

		attr_accessor :user

		def initialize board, index
			@board = board
			@index = index
			@position =	@board.index_to_position index
			@user = nil
		end
	end
end

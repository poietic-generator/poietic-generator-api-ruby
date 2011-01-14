

module PoieticGen
	class Zone <
		Struct.new :index, :position, :vector, :user

		def initialize index, position, vector
			@index = index
			@position = position
			@vector = vector
			@user = nil
			@zone_width = 32
			@zone_height = 32
		end

		def next_index
			return (@index + 1)
		end

		def next_position
			x = @position[0] + @vector[0]
			y = @position[1] + @vector[1]
			return [x,y]
		end

		def next_vector
			v = [ - @vector[1], @vector[0] ]
			return v
		end

		def self.create_next zone
			return self.new zone.next_index, 
				zone.next_position, 
				zone.next_vector
		end

	end
end

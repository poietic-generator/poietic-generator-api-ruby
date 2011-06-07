
module PoieticGen ; module Allocation
	module Spiral

		# helper class fir direction
		class V
			attr_accessor :x, :y

			def initialize x, y
				@x, @y = x, y
			end

			def rotate_left!
				@x, @y = -@y, @x
				#puts "rotate! now %s" % self
				self
			end

			def rotate_right!
				@x, @y = -@y, @x
				self
			end

			def + v
				raise TypeError unless v.is_a? V
				@x += v.x
				@y += v.y
				self
			end

			def - v
				raise TypeError unless v.is_a? V
				@x -= v.x
				@y -= v.y
				self
			end

			def == v
				return false if v.x != @x
				return false if v.y != @y
				return true
			end

			def to_s
				"(%s, %s)" % [ @x, @y ]
			end

			def to_a
				[ @x, @y ]
			end
		end


		def initialize
		end


=begin
test = {
	0 => [0,0],
	1 => [1,0],
	2 => [1,1],
	4 => [-1,1],
	6 => [-1,-1],
	9 => [2,-1]
}

test.each do |idx,pos|
	posv = V.new( pos[0], pos[1] )
	p = idx_to_pos idx
	i = pos_to_idx pos[0], pos[1]

	puts posv, idx
	puts p, i

	raise RuntimeError if p != posv
	raise RuntimeError if i != idx
end
=end


		# index to position
		def idx_to_pos idx
			dir = V.new( 1, 0 )
			pos = V.new( 0, 0 )
			# puts "%s => %s" % [ 0, pos ]
			idx.times do |cnt|
				pos += dir
				# puts "%s => %s" % [ cnt + 1, pos ]
				if pos.x.abs == pos.y.abs then
					unless ( pos.y <= 0 and pos.x == -pos.y ) then
						dir.rotate_left!
					end
				elsif ( pos.y <= 0 and pos.x == -pos.y + 1 ) then
					dir.rotate_left!
				end
			end
			return pos
		end

		# position from index
		def pos_to_idx x, y
			dir = V.new( 1, 0 )
			pos = V.new( 0, 0 )
			idx = 0
			# puts "%s => %s" % [ 0, pos ]
			while ( pos.x != x or pos.y != y ) do
				idx += 1
				pos += dir
				# puts "%s => %s" % [ cnt + 1, pos ]
				if pos.x.abs == pos.y.abs then
					unless ( pos.y <= 0 and pos.x == -pos.y ) then
						dir.rotate_left!
					end
				elsif ( pos.y <= 0 and pos.x == -pos.y + 1 ) then
					dir.rotate_left!
				end
			end
			return idx
			# nothing
		end

	end
end




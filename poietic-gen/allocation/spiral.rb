
class V
	attr_accessor :x, :y

	def initialize x, y
		@x, @y = x, y
	end

	def rotate_left!
		@x, @y = -@y, @x
		puts "rotate! now %s" % self
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

	def to_s
		"(%s, %s)" % [ @x, @y ]
	end
end

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

def pos_to_idx x, y
	# nothing
end

idx_to_pos 0

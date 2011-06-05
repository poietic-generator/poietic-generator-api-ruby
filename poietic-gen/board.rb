
require 'poietic-gen/zone'

module PoieticGen

	#
	# A class that manages the global drawing
	#
	class Board

		private

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


		# 
		# Find the first allocatable index
		#
		def _next_index 
			result_index = nil

			# find a nil zone first
			nil_zones = @zones.select{ |idx,zone| zone.nil? }
			if nil_zones.size > 0 then
				# got an unallocated zone !
				result_index = nil_zones.first[0]
			else
				# try the normal method
				result_index = @zones.size
			end
			return result_index
		end


		public

		#
		#
		#
		def initialize
			# map index => Zone object (or nil if unallocated)
			@zones = {}
		end


		#
		# return index to position
		#
		def index_to_position idx
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
			return pos.to_a
		end


		#
		# return position from index
		#
		def position_to_index x, y
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
		end


		#
		# allocates and return 
		# a zone		
		#
		def allocate user
			next_index = _next_index()

			zone = Zone.new self, next_index
			zone.user = user

			STDERR.puts "Allocation zone : ", zone.inspect

			@zones[next_index] = zone
			return zone
		end

		def free zone_idx
			zone = @zones[zone_idx]
			zone.user = nil
			@zones[zone_idx]
		end

	end

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
	p = index_to_position idx
	i = position_to_index pos[0], pos[1]

	puts posv, idx
	puts p, i

	raise RuntimeError if p != posv
	raise RuntimeError if i != idx
end
=end


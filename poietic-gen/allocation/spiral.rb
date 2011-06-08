
require 'poietic-gen/allocation/generic'
require 'monitor'

module PoieticGen ; module Allocation
	class Spiral < Generic

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
		#
		#
		def initialize config
			# map index => Zone object (or nil if unallocated)
			@zones = {}
			@config = config
			@monitor = Monitor.new

			# FIXME : maintain boundaries for the board
			@boundary_left = 0
			@boundary_right = 0
			@boundary_top = 0
			@boundary_bottom = 0
		end


		def [] index
			return @zones[index]
		end


		#
		# return index to position
		#
		def index_to_position idx
			@monitor.synchronize do 
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
		end


		#
		# return position from index
		#
		def position_to_index x, y
			@monitor.synchronize do 
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
		end


		#
		# allocates and return 
		# a zone                
		#
		def allocate
			next_index = _next_index()

			zone = Zone.new next_index, 
				(self.index_to_position next_index),
				@config.width,
				@config.height

			STDERR.puts "Spiral/allocate zone : ", zone.inspect
			@zones[next_index] = zone
			return zone
		end

		#
		#
		#
		def free zone_idx
			zone = @zones[zone_idx]
			zone.user = nil
			@zones[zone_idx]
		end

		private
		# 
		# Find the first allocatable index
		#
		def _next_index 
			result_index = nil

			@monitor.synchronize do
				# find a nil zone first
				nil_zones = @zones.select{ |idx,zone| zone.nil? }
				if nil_zones.size > 0 then
					# got an unallocated zone !
					result_index = nil_zones.first[0]
				else
					# try the normal method
					result_index = @zones.size
				end
			end
			return result_index
		end



	end
end ; end

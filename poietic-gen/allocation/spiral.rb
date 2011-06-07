
require 'poietic-gen/allocation/generic'

module PoieticGen ; module Allocation
	module Spiral < Generic

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
			dir = V.new( 1, 0 )
			pos = V.new( 0, 0 )
			# puts "%s => %s" % [ 0, pos ]
			idx.times do |cnt|
				pos += dir
				# puts "%s => %s" % [ cnt + 1, pos ]

			end
		end

		private
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


	end




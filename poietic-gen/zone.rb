
module PoieticGen
	class Zone

		attr_reader :index, :position

		attr_accessor :user

		def initialize index, position, width, height
			@index = index
			@position =	position
			@width = width
			@height = height
			@user = nil

			@data = []
			@width.times do |w_cnt|
				@data[w_cnt] = []
				@height.times do |h_cnt|
					@data[w_cnt][h_cnt] = nil
				end
			end
		end

		def apply drawing
			# save patch into database
			STDERR.puts "Zone - apply:"
			return if drawing.nil?

			drawing.each do |patch|
				color = patch['color']
				changes = patch['changes']
				# FIXME: add patch into database
				
				changes.each do |x,y,t_offset|
					@data[x][y] = color
				end
			end
			
		end
	end
end

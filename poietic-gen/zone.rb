
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
				timestamp = patch['stamp']

				# add patch into database
				param_create = {
					:color => color,
					:changes => JSON.generate(changes).to_s,
					:timestamp => DateTime.parse(timestamp)
				}
				pp param_create
				begin
					patch = Stroke.create param_create
					patch.save
				rescue DataMapper::SaveFailureError => e
					puts e.resource.errors.inspect
					raise e
				end

				
				changes.each do |x,y,t_offset|
					@data[x][y] = color
				end
			end
			
		end

		def to_desc_hash 
			res = {
				:index => @index,
				:position => @position,
				:user => @user.id
			}
			return res
		end

		#
		# Return an array out of current zone state
		#
		def to_patches_hash
			result = []
			patches = {}
			@width.times do |w|
				@height.times do |h|
					color = @data[w][h]
					next if color.nil?
					patches[color] = [] unless patches.include? color
					patches[color].push [w,h,0]
				end
			end
			patches.each do |color, where|
				patch = {
					:color => color,
					:changes => where,
					:stamp => nil
				}
				result.push patch
			end
			return result
		end
	end
end

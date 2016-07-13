
require 'poieticgen'

module PoieticGen
	class Zone
		include DataMapper::Resource
		
		property :id,	Serial

		# the position, from center
		property :index, Integer, required: true

		# position
		property :position, Json, required: true, lazy: false
	
		# size attributes
		property :width, Integer, required: true
		property :height, Integer, required: true
		
		property :data, Json, required: true, lazy: false

		property :created_at, Integer, 
		  required: true

		property :expired_at, Integer, 
		  required: true, 
		  default: 0

		property :expired, Boolean, 
		  required: true, 
		  default: false,
		  index: true

		property :is_snapshoted, Boolean, default: false

		belongs_to :board
		belongs_to :user
		has n, :zone_snapshots

		DESCRIPTION_MINIMAL = 1
		DESCRIPTION_FULL = 2
		
		#
		# convert JSON strings to integers
		#
		def position
			super.map{|x| x.to_i}
		end


		def color x, y
			return self.data[_xy2idx(x,y)]
		end

		def initialize index, position, width, height, board
			param_create = {
				index: index,
				position: position.map{|x| x.to_s},
				width: width,
				height: height,
				data: Array.new( width * height, '#000'),
				user: nil,
				created_at: Time.now.to_i,
				board: board
			}
			super param_create
		end
		
		def save
			begin
				super
			rescue DataMapper::SaveFailureError => e
				STDERR.puts "Saving failure : %s" % e.resource.errors.inspect
				raise e
			end
		end
		
		def self.from_snapshot snapshot
			zone = snapshot.zone
			zone.data = snapshot.data
			zone.expired = false
			
			return zone
		end

		def reset
		  # binding.pry
		  # self.attributes # call once to make sure lazy data are loaded
			self.data = Array.new( width * height, '#000')
		end

		def disable
			self.expired_at = Time.now.to_i
			self.expired = true
		end

		def apply drawing
			# save patch into database
			return if drawing.nil? or drawing.empty?

			# STDERR.puts drawing.inspect if drawing.length != 0

			# Sort strokes by time
			drawing = drawing.sort{ |a, b| a['diff'].to_i <=> b['diff'].to_i }

			ref = self.user.last_update_time
     
      # Then update zone
			Zone.transaction do #NC:SMALL
				drawing.each do |patch|
					color = patch['color']
					changes = patch['changes']
					timestamp = patch['diff'].to_i + ref

		      # add stroke into database
					Stroke.create_stroke color,
						JSON.generate(changes).to_s,
						timestamp,
						self

          # update local zone
					changes.each do |x,y,t_offset|
						idx = _xy2idx(x,y)
						if idx >= 0 and idx < self.data.length then
							self.data[idx] = color
						end
					end
				end

				self.is_snapshoted = false
				self.save
			end
		end
		
		#
		# Apply a list of strokes object without saving it into the db
		#
		def apply_local drawing
			return if drawing.nil? or drawing.empty?

			STDERR.puts drawing.inspect if drawing.length != 0

			drawing.each do |patch|

				color = patch.color
				changes = JSON.parse(patch.changes)

				changes.each do |x,y,t_offset|
					idx = _xy2idx(x,y)
					self.data[idx] = color
				end
			end
		end

		def to_desc_hash type
		  content = if type == DESCRIPTION_FULL
                  then self.to_patches_hash
                else [] 
                end
			res = {
				index: self.index,
				position: self.position,
				user: self.user.id,
				content: content
			}
			return res
		end


		#
		# Return an array out of current zone state
		#
		def to_patches_hash
			result = []
			patches = {}

			self.width.times do |w|
				self.height.times do |h|
					color = self.data[_xy2idx(w,h)]
					next if color.nil?
					patches[color] = [] unless patches.include? color
					patches[color].push [w,h,0]
				end
			end
			patches.each do |color, where|
				patch = {
					id: nil,
					zone: self.index,
					color: color,
					changes: where,
					diffstamp: nil
				}
				result.push patch
			end

			return result
		end
		
		def snapshot timeline
			snap = nil

			Zone.transaction do |t|
				unless self.is_snapshoted then
					self.update(is_snapshoted: true)

					snap = ZoneSnapshot.create self, timeline
				else
					snap = self.zone_snapshots.first(order: [:timeline_id.desc])
				end
			end

			return snap
		end

		private

		def _xy2idx x,y
			return (y * self.width + x)
		end

		def _idx2xy idx
			x = idx % self.width
			y = idx / self.width
			return x,y
		end
	end
end

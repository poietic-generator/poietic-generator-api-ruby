
require 'dm-core'
require 'dm-validations'
require 'dm-types'
require 'poieticgen/board'
require 'poieticgen/user'
require 'poieticgen/transaction'

module PoieticGen

	class Zone
		include DataMapper::Resource
		
		property :id,	Serial

		# the position, from center
		property :index, Integer, required: true

		# position
		# property :position, Json, required: true, lazy: true 
		property :position_x, Integer, required: true
		property :position_y, Integer, required: true
	
		# size attributes
		property :width, Integer, required: true
		property :height, Integer, required: true
		
		#property :data, Json, required: true, lazy: false
		property :pixel_data, Text, required: true, lazy: false

		property :created_at, Integer, required: true
		property :expired_at, Integer, required: true, default: 0
		property :expired, Boolean, required: true, default: false

		property :is_snapshoted, Boolean, default: false

		belongs_to :board
		belongs_to :user
		has n, :zone_snapshots

		DESCRIPTION_MINIMAL = 1
		DESCRIPTION_FULL = 2
		
		#
		# convert JSON strings to integers
		#
		# def color x, y
		# 	return self.data[_xy2idx(x,y)]
		# end

		def initialize index, position, width, height, board
			param_create = {
				index: index,
				position_x: position[0],
				position_y: position[1],
				width: width,
				height: height,
				pixel_data: JSON.generate(Array.new( width * height, '#000')),
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
			zone.pixel_data = snapshot.pixel_data
			zone.expired = false
			
			return zone
		end

		def reset
		  # binding.pry
		  # self.attributes # call once to make sure lazy data are loaded
			self.pixel_data = JSON.generate(Array.new( width * height, '#000'))
		end

		def disable
			self.expired_at = Time.now.to_i
			self.expired = true
		end

		def apply drawing
			# save patch into database
			return if drawing.nil? or drawing.empty?

			STDERR.puts drawing.inspect if drawing.length != 0

			# Sort strokes by time
			drawing = drawing.sort{ |a, b| a['diff'].to_i <=> b['diff'].to_i }

			Zone.transaction do |t|
				begin
					ref = self.user.last_update_time
					pixel_data = JSON.parse(self.pixel_data)

					drawing.each do |patch|

						color = patch['color']
						changes = patch['changes']
						timestamp = patch['diff'].to_i + ref

						# add patch into database
						Stroke.create_stroke color,
							JSON.generate(changes).to_s,
							timestamp,
							self

						changes.each do |x,y,t_offset|
							idx = _xy2idx(x,y)
							if idx >= 0 and idx < pixel_data.length then
								pixel_data[idx] = color
							end
						end
					end

          self.pixel_data = pixel_data
					self.is_snapshoted = false

					self.save

				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Zone.apply"
					raise e

				rescue Exception => e
					pp "apply.Exception"
					t.rollback
					raise e
				end
			end
		end
		
		#
		# Apply a list of strokes object without saving it into the db
		#
		def apply_local drawing
			return if drawing.nil? or drawing.empty?

			STDERR.puts drawing.inspect if drawing.length != 0

      pixel_data = JSON.parse(self.pixel_data)
			drawing.each do |patch|
				color = patch.color
				changes = JSON.parse(patch.changes)

				changes.each do |x,y,t_offset|
					idx = _xy2idx(x,y)
					pixel_data[idx] = color
				end
			end
			self.pixel_data = JSON.generate(pixel_data)

		end

		def to_desc_hash type
		  content = if type == DESCRIPTION_FULL
                  then self.to_patches_hash
                else [] 
                end
			res = {
				index: self.index,
				position: [self.position_x, self.position_y],
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

      pixel_data = JSON.parse(self.pixel_data)
			self.width.times do |w|
				self.height.times do |h|
					color = pixel_data[_xy2idx(w,h)]
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
				begin
					unless self.is_snapshoted then
						self.update(is_snapshoted: true)

						snap = ZoneSnapshot.create self, timeline
					else
						snap = self.zone_snapshots.first(order: [ :timeline_id.desc ])
					end
				rescue DataObjects::TransactionError => e
					Transaction.handle_deadlock_exception e, t, "Zone.snapshot"
					raise e

				rescue Exception => e
					pp "snapshot.Exception"
					t.rollback
					raise e
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

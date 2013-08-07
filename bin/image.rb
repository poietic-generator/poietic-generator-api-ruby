#!/usr/bin/env ruby

require 'chunky_png'

module PoieticGen
	module CLI
		# Image interface
		class Image < ChunkyPNG::Image
			def initialize width, height, fill=nil
				if fill == nil then
					fill = ChunkyPNG::Color::TRANSPARENT
				end
				
				super width, height, fill
			end


			def set_pixel x, y, color
				super x, y, color
			end


			def save filename
				super filename
			end
		end


		class Color
			def self.from_hex color
				# Converts #RGB codes to #RRGGBB
				if color.length == 4 then
					if color[0] == '#' then
						color = color[1] + color[1] +
							color[2] + color[2] +
							color[3] + color[3]
					end
				end
				return ChunkyPNG::Color.from_hex color
			end


			def self.from_rgb r, g, b
				return ChunkyPNG::Color.rgb r, g, b
			end
			
			def self.to_rgb color
				return ChunkyPNG::Color.to_truecolor_bytes color
			end
		end
	end
end


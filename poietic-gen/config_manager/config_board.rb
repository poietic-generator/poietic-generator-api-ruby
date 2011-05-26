
module PoeticGen ; class ConfigManager

	#
	#
	#
	class ConfigBoard

		attr_reader :name
		attr_reader :allocator
		attr_reader :colors
		attr_reader :width
		attr_reader :height
		# FIXME : fix width and height name

		#
		#
		#
		def initialize hash
			raise MissingField, "Board.name" unless hash.include? "name"
			@name = hash["name"]

			raise MissingField, "Board.allocator" unless hash.include? "allocator"
			case hash["allocator"].strip.downcase
			when /^spiral$/ then @allocator = "spiral"
			when /^random$/ then @allocator = "random"
			else raise BadFieldType, "Board.adapter must be [spiral|random]"
			end

			raise MissingField, "Board.colors" unless hash.include? "colors"
			case hash["colors"].strip.downcase
			when /^ansi$/ then @colors = "ansi"
			when /^truecolor$/ then @colors = "truecolor"
			else raise BadFieldType, "Board.color must be [ansi|truecolor]"
			end

			raise MissingField, "Board.width" unless hash.include? "width"
			@width = ConfigManager.parse_int hash["width"], "Board.width"

			raise MissingField, "Board.height" unless hash.include? "height"
			@height = ConfigManager.parse_int hash["height"], "Board.height"
		end
	end

end ; end


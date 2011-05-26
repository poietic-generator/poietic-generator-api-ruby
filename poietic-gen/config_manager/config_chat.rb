
module PoieticGen ; class ConfigManager

	class ConfigChat
		attr_reader :enable

		def initialize hash
			raise MissingField, "Chat.enable" unless hash.include? "enable"
			@enable = ConfigManager.parse_bool hash["enable"], "Chat.enable"
		end
	end

end ; end

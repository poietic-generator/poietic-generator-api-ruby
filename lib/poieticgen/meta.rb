
module PoieticGen
	class Meta
		include DataMapper::Resource

		property :id,	Serial
		property :name, String, required: true, index: true
		property :value, Text,  required: true, lazy: false
	end
end

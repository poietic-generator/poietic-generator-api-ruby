
module PoieticGen
	#
	#
	#
	class Page < Struct.new :title, :css, :js
		#
		#
		#
		def initialize title="untitled", css=[], js=[]
			super
		end

		def render_css
			res = ""
			css.each do |css_file|
				res << "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{css_file}\" />\n"
			end
			return res
		end
	end
end

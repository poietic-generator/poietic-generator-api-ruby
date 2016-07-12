
# require 'pry'
# require 'ruby-prof'
# RubyProf.start
# RubyProf.pause
# 
# at_exit do
#   result = RubyProf.stop
#   printer = RubyProf::MultiPrinter.new(result)
#   printer.print(:path => ".", :profile => "profile")
# end
# 
require 'tilt/haml'
require 'tilt/sass'

require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-types'
require 'dm-constraints'
require 'data_objects'

require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sinatra/flash'

# require 'rdebug/base'
require 'thor'
require 'compass'
require 'haml'
require 'json'
require 'sass'
require 'pp'
require 'oily_png'
require 'duration'

require 'rdebug/base'


require "poieticgen/version"
require 'poieticgen/update_request'

require 'poieticgen/allocation/spiral'
require 'poieticgen/allocation/random'

require 'poieticgen/board'
require 'poieticgen/board_group'
require 'poieticgen/config_manager'
require 'poieticgen/page'
require 'poieticgen/manager'
require "poieticgen/zone"
require "poieticgen/zone_snapshot"
require "poieticgen/user"
require "poieticgen/meta"
require 'poieticgen/timeline'
require 'poieticgen/board_snapshot'
require 'poieticgen/transaction'
require 'poieticgen/image'



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

require 'compass'
require 'haml'
require 'sass'
require 'pp'

require "poieticgen/version"
require 'poieticgen/board'
require 'poieticgen/board_group'
require 'poieticgen/config_manager'
require 'poieticgen/manager'
require "poieticgen/zone"
require "poieticgen/zone_snapshot"
require "poieticgen/user"


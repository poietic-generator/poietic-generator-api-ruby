
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
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-types'
require 'dm-constraints'
require 'data_objects'

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/contrib/all'

# require 'rdebug/base'
require 'thor'
require 'compass'
require 'json'
require 'pp'
require 'duration'

require 'rdebug/base'


require_relative "poieticgen/version"
require_relative 'poieticgen/update_request'

require_relative 'poieticgen/allocation/spiral'
require_relative 'poieticgen/allocation/random'

require_relative 'poieticgen/models/board'
require_relative 'poieticgen/models/board_group'
require_relative "poieticgen/models/zone"
require_relative 'poieticgen/models/stroke'
require_relative "poieticgen/models/user"
require_relative "poieticgen/models/meta"
require_relative 'poieticgen/models/timeline'
require_relative 'poieticgen/models/event'
require_relative 'poieticgen/models/message'

require_relative 'poieticgen/controllers/application_controller'
require_relative 'poieticgen/controllers/spaces_controller'
require_relative 'poieticgen/controllers/sessions_controller'
require_relative 'poieticgen/controllers/authentications_controller'
require_relative 'poieticgen/controllers/registrations_controller'

require_relative 'poieticgen/config_manager'
require_relative 'poieticgen/manager'
require_relative 'poieticgen/transaction'
require_relative 'poieticgen/image'

# require "poieticgen/zone_snapshot"
# require 'poieticgen/board_snapshot'
#

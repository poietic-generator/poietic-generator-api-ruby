
require 'rubygems'
require 'bundler/setup'

require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-types'
require 'dm-contraints'

require 'compass'
require 'haml'
require 'sass'

$:.insert(0,".")
require 'poieticgen/manager'
require 'poieticgen/api'

#use Rack::Session::Cookie

run PoieticGen::Api

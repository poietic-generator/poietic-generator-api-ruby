
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-types'
require 'dm-constraints'

require 'compass'
require 'haml'
require 'sass'

$:.insert(0,".")
require 'poieticgen'

#use Rack::Session::Cookie

run PoieticGen::Api

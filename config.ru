
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
#require 'pry'

$:.insert(0,"lib")

require 'poieticgen'
require 'poieticgen/api'

run PoieticGen::Api

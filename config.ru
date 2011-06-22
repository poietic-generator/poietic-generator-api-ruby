
require 'rubygems'
require 'bundler/setup'

require 'datamapper'
require 'dm-core'
require 'dm-validations'
require 'dm-sqlite-adapter'

require 'poietic-gen/manager'
require 'poietic-gen/api'

use Rack::Session::Cookie

run PoieticGen::Api

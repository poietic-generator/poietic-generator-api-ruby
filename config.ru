
require 'rubygems'
require 'bundler/setup'

require 'dm-core'
require 'dm-validations'
require 'dm-sqlite-adapter'
require 'dm-migrations'

require 'poieticgen/manager'
require 'poieticgen/api'

#use Rack::Session::Cookie

run PoieticGen::Api

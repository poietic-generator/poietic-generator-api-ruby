
require 'rubygems'
require 'bundler/setup'

#require 'datamapper'
require 'dm-core'
require 'dm-validations'

#require 'dm-sqlite3-adapter'

require 'poietic-gen/manager'
require 'poietic-gen/api'

run PoieticGen::Api

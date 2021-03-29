
# start profiling before requiring sinatra
$:.insert(0,"lib")

require 'poieticgen'
require 'poieticgen/api'

run PoieticGen::Api


# start profiling before requiring sinatra
$:.insert(0,"lib")

require 'poieticgen'
require 'poieticgen/api'

# Faye::WebSocket.load_adapter 'thin'
# use Faye::RackAdapter, mount: '/ws', timeout: 45, extensions: []

run PoieticGen::Api

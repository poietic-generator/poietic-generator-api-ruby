worker_processes 5
timeout 15
preload_app true

before_fork do |server, worker|
  DataObjects::Pooling.pools.each do |pool| 
    pool.dispose 
  end
end

after_fork do |server, worker|
  # nothing ?
end

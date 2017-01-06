
require 'clockwork'
module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  # every(1.minutes, 'backup.save.zones')
  every(5.minutes, 'backup.export.images')
  every(1.hour,    'backup.export.video')

  # every(1.day, 'midnight.job', :at => '00:00')
end

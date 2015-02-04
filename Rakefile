
#
# Display tasks list if none specified
#

ROOT_DIR = File.expand_path(File.dirname __FILE__)

require 'rake'
require 'rake/testtask'

# Mark all defined tasks
Rake::TaskManager.record_task_metadata = true

# Import tasks from exteranal files
Dir.glob('tasks/*.rake').each { |r| import r }


# Set default task to list all task
task :default do
  	puts "Usage : rake <taskname>"
  	puts ""
  	Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  	Rake::application.options.show_task_pattern = //
  	Rake::application.display_tasks_and_comments
end

#task :default => :test



namespace :gem do
	# Import GEM-related tasks
	require "bundler/gem_tasks"
	Rake::TestTask.new do |t|
        #t.warning = true
        #t.verbose = true
        t.libs << "spec"
        t.test_files = FileList['spec/**/*_spec.rb']
	end
end


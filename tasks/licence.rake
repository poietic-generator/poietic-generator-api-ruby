
require 'mkmf'

desc "Update licence headers in all files."
task :license do 
	fail "Unable to find 'headache' binary" unless find_executable "headache"
	%x{
	find lib bin -name '*.js' -or  -name '*.rb' |while read NAME ; do \
		headache -c misc/headache.conf -h misc/header.txt $$NAME ; \
	done
	}
end

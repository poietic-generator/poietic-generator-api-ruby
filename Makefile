

all:

headers:
	find . -name '*.js' -or  -name '*.rb' |while read NAME ; do \
		headache -c misc/headache.conf -h misc/header.txt $$NAME ; \
	done


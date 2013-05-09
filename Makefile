

all:

headers:
	find poieticgen -name '*.js' -or  -name '*.rb' |while read NAME ; do \
		headache -c misc/headache.conf -h misc/header.txt $$NAME ; \
	done

%.html: %.md
	markdown $< > $@

doc: API.html Readme.html

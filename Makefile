#!/usr/bin/make -f

include site.minfo

all: sites-available/qr.conf seq.simple list2csv

clean:
	rm sites-available/qr.conf Inventory/Config.pm

%: %.sm simple_macro site.minfo
	./simple_macro site.minfo $<


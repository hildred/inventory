#!/usr/bin/make -f

include site.minfo

all: sites-available/qr.conf Inventory/Config.pm

clean:
	rm sites-available/qr.conf Inventory/Config.pm

%: %.sm simple_macro site.minfo
	./simple_macro site.minfo $<

edit:
	gvim ./seq.simple ./list2csv *.list

%.pdf: %.csv avery5160.glabels
	#if you have a patched version of glabels (https://github.com/jimevins/glabels/pull/65) use it.
	~/glabels-3.4.0/debian/tmp/usr/bin/glabels-3-batch -C -i $< -o $@ avery5160.glabels 2>/dev/null 
	#otherwise strip extra messages from stdout.
	#glabels-3-batch -C -i $< -o $@ avery5160.glabels

%.print: %.pdf
	# This assumess the cups version of lpr.
	# You may want to change the input slot.
	lpr -o sides=one-sided -o Ink=MONO -o InputSlot=Rear "$<"

%.test: %.pdf
	xpdf $<

%.csv: %.list Inventory/Config.pm
	./list2csv $< >$@

item.csv: Inventory/Config.pm
	./seq.simple ITEM >$@

box1.csv: Inventory/Config.pm
	./seq.simple BOX/1 >$@

box2.csv: Inventory/Config.pm
	./seq.simple BOX/2 >$@

box3.csv: Inventory/Config.pm
	./seq.simple BOX/3 >$@


#!/bin/perl

@l = ();
while(<>) {
	chomp;
	next if /^\s*;/;
	if(/^\s*\$/) {
		while(s/\$([0-9a-fA-F]+)//) {
			push(@l, eval("0x$1"));
		}
	} elsif(/^\s*%/) {
		while(s/%([0-1]+)//) {
			push(@l, eval("0b$1"));
		}
	} elsif(/^\s*§/) {
		my($i, @t)=0;
		y/.X/01/;
		while(s/([01])([01])//) {
			$t[$i++] = eval("0b$2$1");
		}
		$_ = <>; chomp; $i=0;
		y/.X/01/;
		while(s/([01])([01])//) {
			$t[$i] |= eval("0b$2$1")<<2;
			++$i;
		}
		$_ = <>; chomp; $i=0;
		y/.X/01/;
		while(s/([01])([01])//) {
			my($t) = eval("0b$2$1");
			$t[$i] |= ($t<<1|$t|2)<<4;
			++$i;
		}
		push(@l, @t);
	} else {
		push(@l, unpack("c*", $_));
	}
}

#print pack('c*', @l);
for($i=0; $i<=$#l; $i+=6) {
    print "       fcb    ";
    for(my $j=0; $j<6 && $i+$j<=$#l; ++$j) {
         print "," if $j;
	 print sprintf("\$%02x", $l[$i+$j]);
    }
    print "\n";
}

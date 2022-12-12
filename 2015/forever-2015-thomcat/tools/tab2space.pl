#!/bin/perl
# Conversion tab->espace

while(<>) {
	my $l = "";
	chomp;
	for my $c (unpack('C*', $_)) {
		if($c == 9) {
			do {$l .= ' ';} while(length($l) & 7);
		} else {$l .= chr($c);}
	}
	$l =~ s/\s*$//;
	print "$l\n";
}
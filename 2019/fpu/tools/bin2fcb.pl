#!/bin/perl

# on charge tout dans la mémoire
@m = (); $z = 0; $s=0xFFFF;
while(1) {
	my($t) = &c;
	if($t == 0) {
		$l = &w;
		$a = &w;
		$s = $a if $a<$s;
		while($l--) {$m{$a++} = &c;}
		$z = $a if $a>$z;
	} if($t == 255) {
		&w;
		$e = &w;
		last;
	}
}

# on dump le code ASM avec les FCB
print "*"x40,"\n";
print sprintf("* debut  : \$%04X\n", $s);
print sprintf("* fin    : \$%04X\n", $z-1);
print sprintf("* taille : %d\n", $z-$s);
print "*"x40,"\n";
for($x=$s; $x<$z; ++$x) {
	print sprintf("\n\torg\t\$%04X\n\n", $x);
	if($x == $e) {
		print "\n" if $i;
		$i = 0;
		print "init";
	}
	for($i = 0; defined($m{$x}); ++$x) {
		print "\tfcb\t" if $i==0;
		print ","   unless $i==0;
		print sprintf("\$%02X", $m{$x});
		if(++$i==5) {
			print "\n";
			$i = 0;
		}
	}
	print "\n" if $i;
}
print sprintf("\n\tend\tinit\n", $e);



sub w {
	my($t) = &c;
	return $t*256 + &c;
}

sub c {
	sysread(STDIN, $_, 1) || return undef;
	@t = unpack('C', $_);
	return $_ = $t[0];
}
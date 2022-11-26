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

$line = 0;
print sprintf("%d CLEAR,&H%04X\n", $line+=10, $s-1);
print sprintf("%d COLOR7,0:SCREEN,,0:CLS:LOCATE0,0,0\n", $line+=10);
print sprintf("%d FORI=0TO199:PSET(0,I),2^(I MOD3):PSET(0,I),-1:NEXT\n", $line+5);
print sprintf('%d READ A$:IF LEN(A$)=4 THEN A=VAL("&H"+A$):GOTO %d', $line+=10,$line),"\n";
print sprintf('%d IF A$="**" THEN EXEC A ELSE POKE A,VAL("&H"+A$):A=A+1:GOTO %d', $line+=10, $line-10),"\n";

# on dump le code ASM avec les FCB
for($x=$s; $x<$z; ++$x) {
	print sprintf("%d DATA %04X\n", $line+=10, $x) if defined($m{$x});
	for($i = 0; defined($m{$x}); ++$x) {
		print $line+=10," DATA " if $i==0;
		print ","            unless $i==0;
		print sprintf("%02X", $m{$x});
		if(++$i==10) {
			print "\n";
			$i = 0;
		}
	}
	print "\n" if $i;
}
print sprintf("%d DATA %04X,**\n", $line+=10, $s);

sub w {
	my($t) = &c;
	return $t*256 + &c;
}

sub c {
	sysread(STDIN, $_, 1) || return undef;
	@t = unpack('C', $_);
	return $_ = $t[0];
}
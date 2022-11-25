#!/bin/perl
# Compression de fichier "quat" pour le
# player "buzzer" thomson.
#
# (c) Samuel Devulder Mars 2016.
#

# no buffering
$| = 1;

$nom = <>; chomp($nom); $nom=~ s/^\s*\*\s*//;
@trk = ();
$str = 0;
while(<>) {
	chomp; next unless /./;
	if($str) {
		$trk[$#trk] .= "\n$_";
		$str = !/ fcb \$0/;
	} else {
		push(@trk, $_);
		$str = / fcb \$83/;
	}
}

@tom = &compress_track(@trk);
$size = &code_size(@tom);
print "* $nom ($size octets)\nzik\n";
for my $t (@tom) {print $t,"\n";}
print "* $size octets ($nom)\n";

exit(0);

sub compress_track {
	my(@t) = @_;
	return @t if 0;
	push(@t, " fdb 0");

	print STDERR "Compression(",&code_size(@t),")...";
	
	@t = &compress_UNCHG(@t);
	
	#@t = compress_sXX(@t);
	#@t = compress_LZ(@t);
	#@t = compress_rpt(@t);
	@t = &compress_SAM(@t);
	@t = &compress_3pl(@t);
	
	print STDERR "(",&code_size(@t),")...done\n";
	return @t;
}

sub compress_3pl {
	my(@data) = @_;
	my(%note);
	print STDERR "...NOTES";
	for my $t (@data) {
		my $l = $t;
		while($l =~ s/,(...,...,...)$//) {
			my $note = $1;
			my $n = $note{$note};
			$note{$note} = 1 unless defined($n);
		}
	}
	my(@note) = sort keys % note;
	for my $i (0..$#note) {
		my $n = $note[$i];
		$note{$n} = $i;
		$note[$i] = " fcb $n ; note #$i";
	}
	for my $t (@data) {
		my($l);
		while($t =~ s/,(...,...,...)$//) {
			my $n = $note{$1};
			$l = ",$n$l";
		}
		$t.=$l;
	}
	die unless $#note<=255;
	return (" fdb ptn", @note,"ptn",@data);
}

# taille d'un code en octet
sub code_size {
	my($l, @in) = (0, @_);
	for my $s (@in) {my @t = split(/,/,$s); $l += (1+$#t)*($s=~/ fcb /?1:$s=~/ fdb /?2:0);}
	return $l;
}

sub compress_UNCHG {
	my(@data) = (@_);
	
	print STDERR "UNCHG...";
	
	for(my $i=$#data; $i>0; --$i) {
		my $l = $data[$i];   next unless $l=~/ fcb /;
		my $p = $data[$i-1]; next unless $p=~/ fcb /;

		my(@p) = split(/,/,$p);
		my(@l) = split(/,/,$l); next unless $#p==$#l;
		
		$l[0] =~ s/[^\$]*\$//; $l[0] = eval("0x$l[0]");
		
		for(my($j,$k,$m)=(2,2,64); $j<$#p; $j+=3, $m>>=1) {
			if(join("",@l[$k..$k+2]) eq join("",@p[$j..$j+2])) {
				splice(@l, $k, 3);
				$l[0] |= $m;
			} else {
				$k += 3;
			}
		}
		$l[0] = sprintf("\$%02x",$l[0]);
		$data[$i] = " fcb ".join(',', @l);
	}
	
	return @data;
}

sub compress_SAM {
	local(@data) = (@_);
	
	#$DBG = 1;
	
	print STDERR "SAM";
	
	while(1) {
		print STDERR "(",&code_size(@data),")...";
		#for my $i (@data) {print "$i\n";}
	
		# ajout du semaphore
		# push(@data, "--END--");

		my($forbid, @forbid) = (0);
		for my $l (@data) {
			$forbid = 1 if(!$forbid && $l=~/ fcb \$83/);
			push(@forbid, $forbid);
			$forbid = 0 if($forbid && $l=~/ fcb \$0/);
		}
	
		# conversion symboles -> entier (plus rapide)
		my(%h, @d);
		for my $s (@data) {
			$h{$s}=keys %h unless defined $h{$s};
			push(@d, $h{$s});
		}
		undef %h;
		print STDERR ".sort";

		# tri
		my(@t) = sort { my($i,$j) = ($a,$b);
			while($d[$i++] == $d[$j++]) {}
			$data[--$j] cmp $data[--$i];
		} (0..$#data-1);
		
		print STDERR ".patt";		
		# recherche des motifs répétitifs
		my(%gain, %xgain, $last, %precalc);
		&perc(0);
		for(my $i=0; $i<$#t; ++$i) {
			#print STDERR "$i / $#t \r";
			&perc($i/$#t);
			my($deb) = $t[$i];
			my($len) = &pfx($deb, $t[$i+1], \@d);
			
			next if $forbid[$deb] || $forbid[$deb+$len-1];
			
			--$len if $data[$deb+$len-1] eq " fdb 0";
			#print STDERR ">>>", $data[$deb+$len-1], "\n";
					
			# taille du code local
			my($k) = join(',',@data[$deb..$deb+$len-1]);
			my($cz) = &code_size(@data[$deb..$deb+$len-1]);

			# saute si trop petit
			next if $cz<=2+2+2;
				
			# saute si déjà traité
			next if $last eq $k; $last = $k; 
		
			# trouve les répétitions
			my(@o) = &occurs($deb, $len, $i, \@t, \@d);
			
			# gain possible
			my($gain) = $cz*($#o+2) - ($cz + 2 + 2*($#o+1));
			
			# saute si aucun gain
			next if $gain<=0;
			
			$gain{$i} = $gain;
			$precalc{$i} = "$deb,$len,".join(',', @o);
		}
		&perc(1.1);
		undef %done;
		
		# si aucun gain => terminé
		last unless %gain;
		
		# tri des motifs par gains
		print STDERR ".sort";	
		my(@ordered) = sort {$gain{$b} <=> $gain{$a} || $b<=>$a} (keys %gain);
		undef %gain; undef %xgain;
		
		# placement + bibliotheque
		print STDERR ".alloc";
		my(@alloc) = (0) x $#data;
		my(@lib, %lbl);
		for my $i (@ordered) {
			my($deb, $len, @o) = split(/,/, $precalc{$i});
		
			# on verifie qu'il n'y a pas de chevauchement
			my($used) = 0;
			for my $o (@o) {for my $j (0..$len-1) {$used |= $alloc[$j+$o];}}
			next if $used;
			
			# les octets sont marqués 
			# 0                   => pas dans lib --> recopié
			# 2*(i+1)+1 => impair => début de lib --> devient cJSR
			# 2*(i+1)+0 => pair>1 => code de lib --> pas recopié
			for my $o (@o) {
				for my $j (0..$len-1) {$alloc[$j+$o] = 2*($i+1);}
				$alloc[$o] |= 1;
			}
			
			$lbl{$i} = &tmp_lbl;
			push(@lib, $lbl{$i}, 
			           @data[$deb...$deb+$len-1],
					   " fdb 0");
		}
		undef %precalc;
		print STDERR ".score";
	
		# generation du code
		my(@out);
		for my $j (0..$#data) {
			if(!$alloc[$j]) {
				push(@out, $data[$j]);
			} elsif($alloc[$j] & 1) {
				my($i) = $alloc[$j]>>1;
				my($lbl) = $lbl{$i-1};
				push(@out, " fdb $lbl-zik");
			}
		}
		@data = (@out, @lib);
	}	

	return @data;
}

sub perc {
	my($perc) = @_;
	
	if($perc>0) {
		my($z) = int($perc*100);
		return if $z == $glb_perc_last;
		$glb_perc_last = $z;
	}
	
	my($t) = time;
	if($perc<=0) {
		$glb_perc_time = $t;
	} elsif($perc>=1) {
	        print STDERR " " x length($glb_perc_txt), "\b" x length($glb_perc_txt);
		undef $glb_perc_last;
		undef $glb_perc_time;
		undef $glb_perc_txt;
	} elsif($t>$glb_perc_time+30) {
		my($old) = length($glb_perc_txt);
		$glb_perc_txt = sprintf("%3d%% (%ds rem)", $perc*100, int(($t-$glb_perc_time)*(1/$perc-1)));
		my($end) = " " x ($old-length($glb_perc_txt));
		print STDERR $glb_perc_txt, $end, "\b" x (length($glb_perc_txt) + length($end));
	}
}

sub occurs {
	my($s,$l, $i,$t, $d, @r) = @_;

	while($i<$#{$t} && &pfx($s,$t->[++$i],$d)>=$l) {}
	#print "? ",join(' ', @data[$s..$s+$l-1]);
	
	while(--$i>=0 && (&pfx($s,$t->[$i],$d)>=$l)) {push(@r, $t->[$i]);};
	@r = sort {$a<=>$b} @r;
	
	#print STDERR "occurs ", join(',', @r), "\n";
	
	# remove overlapping elements
	for($i=0; $i<$#r;) {if($r[$i]+$l-1>=$r[$i+1]) {splice(@r, $i+1, 1, ());} else {++$i;}}
		
	#print "=$joint ",join(' ',@r),"\n";
	
	return (@r);
}

sub pfx {
	my($s, $t, $d) = @_;
	
	return $#{$d}+1-$s if $s==$t;
	
	#print STDERR "pfx $s,$t";
	my($i) = 0;
	while($d->[$s+$i]==$d->[$t+$i]) {++$i;}
	#print STDERR "=> $i\n";
	return $i;
}

# retourne un label temporaire statistiquement unique
sub tmp_lbl {
	if(!$glb_lbl) {
		$glb_lbl = "A";
		for(my $j=26*26*26*rand; $j-->0;) {++$glb_lbl;}
		$glb_lb1 = 0;
	}
	return $glb_lbl.($glb_lb1++);
}

#!/bin/perl
# conversion de fichier midi en vfier 

# http://www.sonicspot.com/guide/midifiles.html

# no buffering
$| = 1;

# frequence de base
$glb_period = 125;
$glb_noire = 0b00100000;
	
# décalage
$glb_pitch = undef;

# nombre de notes maxi dans un arpège
$glb_arpg_max = 4;

# utilisation du noise ?
$glb_noise = 0;

# skyline par instrument
$glb_skyline_per_inst = 0;

# volume constant
$glb_vol = undef;

# -loop <0|1|2> -track a,b,c file.mid
@files = ();
%glb_tracks = ();
$prev = "";
for $curr (@ARGV) {
	if(-e $curr) {push(@files, $curr);}
	if("-h" eq $curr) {&usage;}
	if("-p" eq $prev) {$glb_pitch = $curr;}
	if("-n" eq $prev) {$glb_arpg_max = $curr;}
	if("-i" eq $curr) {$glb_skyline_per_inst = 1;}
	if("-d" eq $curr) {$glb_noise = 1;}
	if("-x" eq $prev) {
		my($i, @t) = (0, split(/,/,$curr));
		foreach $i (split(/,/, $curr)) {$glb_tracks{$i} = -1;}
	}
	$prev = $curr; 
}

@trk = ();
$file = "";
for my $f (@files) {
	$file .= ",$f";
	my @t = &read_midi($f);
	@t = &norm_bpm(@t);
	@t = &norm_inst(@t);
	push(@trk, &convert($glb_arpg_max, 0.5, @t));
}
die "file=$file" unless $file;
$file=~s/^,//;

#print "\n\n";
#for $k (keys %stat) {$tats{$stat{$k}} = $k;}
#for $k (sort {$a<=>$b} keys %tats) {
#	print sprintf("%6d => %d\n", $tats{$k}, $k);
#}
#exit;

#@trk = &convert($glb_arpg_max, 0.5, @trk);
@tom = &compress_track(@trk);
$size = &code_size(@tom);
$nom = "";
for my $f (split(/,/, $file)) {
	$f="./$f";
	$f=~/.*[\/\\](.*)(\.[^\.]*)?/;
	$nom .= ", $1";
}
$nom=~s/^, //;
print "* $nom ($size octets)\nzik\n";
for my $t (@tom) {print $t,"\n";}
print "* $size octets ($nom)\n";

exit(0);


sub usage {
	print __FILE__, " [-h] [-p <pitch-offset>] [-n <MIP>] [-s] [-d] [-x <t1,t2,t3,...>] <file.mid>";
	exit(0);
}

sub convert {
	my($glb_arpg_max, $tol, @zik) = @_;

	print STDERR "Conversion...";
	
	my(@trk, $i);
	local($vol_max);
	my($vol_fcn) = sub {
		my($v) = @_;
		return 0x80 if $v>$vol_max/2;
		return 0x40 if $v>$vol_max/4;
		return 0x20 if $v>$vol_max/8;
		return 0x10 if $v>$vol_max/16;
	};
	my(%note); # notes théoriquements jouées
	my($curr, $inst, $lvol) = (0, -1, 0);  # derniere note jouée
	my($time, $next, $chl, $key, $vol);      # dernier instant
	
	my($last_tempo) = 0;
	my(@bpm) = (sort {$a <=> $b} keys %glb_bpm);
	
	my(%bend);

	for($i=0; $i<=$#zik;) {
		($time, $chl, $key, $vol) = @{$zik[$i]};
		
		# nouveau tempo?
		if($#bpm>=0 && $bpm[0]<=$time) {
			my $bpm = $glb_bpm{shift(@bpm)};
			my($tempo) = int(60000000/$glb_noire/$glb_period/$bpm);
			#print "$bpm=>$tempo\n";
			push(@trk, sprintf(" fdb \$82%02x", $last_tempo = $tempo)) if $tempo!=$last_tempo;
		}
		
		# bend?
		if($chl<0) {
			$chl = -$chl-1;
			my $bend = ($key-0x2000)/(0x1000+0.0); # arrondi0x
			delete $bend{$chl} unless $bend;
			$bend{$chl} = $bend;
			do {
				($next, $chl, $key, $vol) = @{$zik[++$i]};
			} while($time==$next && $i<=$#zik);
		} else {			
			# calcule dans %note les notes jouees a l'instant $time
			do {
				my($k) = abs($key).",$chl";
				
				#print "$time $chl $key $vol\n";
				if($key>0) {
					my($v) = $note{$k} & 1023;
					$v = $vol if $vol>$v;
					$note{$k} &= ~1023;
					$note{$k} += $v + 1024;
				} else {$note{$k} -= 1024;}
				delete $note{$k} if $note{$k} < 1024;
				($next, $chl, $key, $vol) = @{$zik[++$i]};
			} while($time==$next && $i<=$#zik);
		}
		
		my($delay) = &time2tick($next - $time);
				
		my(%imp) = &important_notes($tol, %note);
		
		# trier max->min
		my(@k) = (0,0,0,0, sort keys %imp);
		my(@v);
		while($#k>=4) {shift(@k);}
		for my $k (@k) {
			my $v = $imp{$k} & 1023;
			push(@v, $v);
			$vol_max = $v if $v>$vol_max;
		}
		
		# percussions non interruptives mais ayant la priorité 
		my($nz, $nnz) = (0,0);
		my($min_z) = 1000;
		my(%bend_k);
		while(my ($k, $v_) = each %note) {
			my($v) = $v_ & 1023;
			my($z,$ch) = split(',', $k);
			$bend_k{$z} = $bend{$ch};
			
			next if $ch!=9;
			$min_z = $z if $z<$min_z;
 			$nz += $v*$v if $glb_noise;
			++$nnz if $glb_noise;
		}
		$nz = sqrt($nz/$nnz) if $nnz>0;
		my($nz_r) = 0.7**($min_z / 36);
		
		# print STDERR "$nz $vol_max\n";
		#$k[0] = $min_z if $nz>0;
	

		for my $k (@k) {$k = &period($k+$bend_k{$k});}
		#print join("|", @k), "\n";
		
		my($last_nz_vol, $last_nz_dur) = (0,0);
		while($delay>0) {
			my $d = $nz>0? 1 : $delay>=255?255:$delay;
			my($cmd) = sprintf(" fdb \$%x,\$%02x%02x,\$%02x%02x,\$%x,\$%x,\$%x,\$%x", 
				$d + 0x8000 + ($nz>0?256:0),
				$vol_fcn->($v[3]),$vol_fcn->($v[2]),$vol_fcn->($v[1]),$vol_fcn->($nz>0?$nz:$v[0]), 
				$k[3],$k[2],$k[1],($nz>0 ? 123 : $k[0]));
			my($push) = 1;
			
			if(@trk) {
				my($c1) = $trk[$#trk];
				my($c2) = $cmd;
				$c1 =~ s/..,/__/; my $v1 = eval("0x$&"); 
				$c2 =~ s/..,/__/; my $v2 = eval("0x$&"); 
				if($c1 eq $c2 && ($v1+$v2)<=255) {
					my $t = sprintf("%02x", $v1+$v2);
					$trk[$#trk] =~ s/..,/$t,/;
					$push = 0;
				}
			}
			
			push(@trk, $cmd) if $push;
			$delay -= $d;
			$nz = int($nz * $nz_r);
			#$nz = 0; # <== bruit très court
		}
	}
	print STDERR "done\n";
	
	#print join("\n",@trk);
	
	return @trk;
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

# https://newt.phys.unsw.edu.au/jw/graphics/notes.GIF
sub freq {
	my($key) = @_;
	my($f) = $glb_freq{$key};
	$glb_freq{$key} = $f = int(440*(2**(($key-69.0)/12))) unless defined $f;
	return $f;
}

sub key {
	my($f) = @_;
	return int(69+12*log($f/440)/log(2));
}

sub period {
	my($key) = @_;
	return 0 unless $key;
	my($f) = &freq($key);
	#print "f=$f k=$key\n";
	# 1/250µs = 4000hz --> 32768
	# 1/500µs = 2000hz --> 16384
	#print "key=$key f=$f --> ", int(32768*$f*$glb_period/500000), "\n";
	
	return int(32768*$f*$glb_period/500000);
}

# calcule le spectre d'une note
sub spectrum {
        my($key, $vol) = @_;
        my(%vol, $m);

        my($f) = &freq($key);

        $vol{$key} += $vol; #&ampl($vol, $f);
        foreach $m (3, 5, 7, 9) {
                last if $f*$m>$glb_max_freq;
                $vol{&freq2note($f*$m)} += $vol/($m**5);
        }
        return %vol;
}

sub important_notes {
	my($tol, %note) = @_;
	my(%sp, %keys, $key, $vol);
	
	if(1) {
		my(%sp) = %note;
		while(my ($k, $v) = each %sp) {$note{$k} = $v & 1023;}
	}
	
	if($glb_noise) {
		my(%sp) = %note;
		while(my ($k, $v) = each %sp) {
			my($z,$i) = split(',', $k);
			delete $note{$k} if $i==9;
		}	
	}
		
	if($glb_skyline_per_inst) {
		# pour chaque channel, on ne garde que la note la
		# plus haute (skyline)
		while(($key, $vol) = each %note) {
			my($k,$i) = split(',', $key);
			$sp{$i} = $k if $k>$sp{$i};
		}
		while(my ($i, $k) = each %sp) {$keys{"$k,$i"} = $note{"$k,$i"};}
		%note = %keys; %keys = (); %sp = ();
	}
	
	# calcul du spectre: on prends le sup
	# autre possibilite: on somme les harmoniques
	my($p) = 2;
	while(($key, $vol) = each %note) {
		my($k,$i) = split(',', $key);
		$sp{$k} += $vol**$p;
		#$sp{$k} = $vol if $vol>$sp{$k};
		#$sp{$k} = 63 if $sp{$k}>63;
	}
	for $key (keys %sp) {
		$sp{$key} = int($sp{$key}**(1/$p));
		$sp{$key} = 63 if $sp{$key}>63;
	}
	%note = %sp; %sp = ();
	
	#	print join(' ', %note),"\n";

	while(($key, $vol) = each %note) {
		my(%z) = &spectrum($key, $vol);
		while(my($k, $v) = each %z) {$sp{$k} += $v;}
	}
	
	if(0) {
	for $key (keys %note) {
		my($f, $g) = &freq($key);
		for $g (2 .. 20) {my($t) = &freq2note($f/$g); delete $note{$t};}
	}
	}
	
	#for $q (keys %note) {print $q,"=>",$note{$q}," ";} print "\n";
	
	
	# on trie les notes par intensité, et à intensité identique
	# par frequence
	my(@k) = (sort {($sp{$a}<=>$sp{$b} or $a<=>$b)} keys %note);
	#for $q (@k) {print $q,"=>",$sp{$q}," ";} print "\n";
	
	while(scalar keys %keys<$glb_arpg_max && $#k>=0) {
		my($t) = pop(@k);
		$keys{$t} = defined $glb_vol?$glb_vol:$note{$t};
	}

	return %keys;
}

sub by_time {
	my($time1, $ch1, $note1, $vol1) = @$a;
	my($time2, $ch2, $note2, $vol2) = @$b;
	
	my($d) = $time1 <=> $time2;
	$d = $note1<=>$note2 unless $d;
	
	return $d;
}

sub print_trk {
	my(@t) = @_;
	my($n);
	
	&flush_line;
	for $n (@t) {&add_note($n);}
	&flush_line;
}

sub compress_track {
	my(@t) = @_;
	return @t if 0;
	push(@t, " fdb 0");

	print STDERR "Compression(",1+$#t,")...";
	
	#@t = compress_sXX(@t);
	#@t = compress_LZ(@t);
	#@t = compress_rpt(@t);
	@t = compress_SAM(@t);
	
	print STDERR "(",1+$#t,")...done\n";
	return @t;
}

# taille d'un code en octet
sub code_size {
	my($l, @in) = (0, @_);
	for my $s (@in) {my @t = split(/,/,$s); $l += 1+$#t if $s=~/ fdb /;}
	return $l*2;
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
			while($d[$i] == $d[$j]) {++$i;++$j;}
			$data[$i] cmp $data[$j];
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
			
			--$len if $data[$deb+$len-1] eq " fdb 0";
			#print STDERR ">>>", $data[$deb+$len-1], "\n";
					
			# taille du code local
			my($k) = join(',',@data[$deb..$deb+$len-1]);
			my($cz) = scalar split(/,/, $k); 

			# saute si trop petit
			next if $cz<=2;
				
			# saute si déjà traité
			next if $last eq $k; $last = $k; 
		
			# trouve les répétitions
			my(@o) = &occurs($deb, $len, $i, \@t, \@d);
			
			# gain possible
			my($gain) = $cz*($#o+1) - ($cz + 1 + 1*($#o+1));
			
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

sub by_data {
	#my($a, $b) = @_;
	my($i) = 0;
	while($data[$a+$i] eq $data[$b+$i]) {++$i;}
	return $data[$a+$i] cmp $data[$b+$i];
}

# tous les instruments doivent être entre C1(24) et C5(72)
sub norm_inst {
	my(@trk) = @_;

	my($fmax) = 1000000/(2*$glb_period);
	my($fmin) = $fmax/32768;
	
	my($nMIN, $nMAX) = (&key($fmin), &key($fmax));
	
	if(0 && !defined $glb_pitch) {
		my($n, $m, $NUM);
		
		for($n=0; $n<9*12; $n+=12) {
			my(%num);
			for $t (@trk) {
				my ($next, $chl, $key, $vol) = @{$t};
				next if $key<0 || ($glb_noise && $chl==9);
				$key += $n;
				$num{$chl} = 1 if $key<$nMIN || $key>$nMAX;
			}
			my($num) = scalar keys %num;
			if($n==0 || $num < $NUM) {$NUM = $num; $m = $n;}
		}
		for($n=0; ($n-=12)>-9*12;) {
			my(%num);
			for $t (@trk) {
				my ($next, $chl, $key, $vol) = @{$t};
				next if $key<0 || ($glb_noise && $chl==9);
				$key += $n;
				$num{$chl} = 1 if $key<$nMIN || $key>$nMAX;
			}
			my($num) = scalar keys %num;
			if($n==0 || $num <= $NUM) {$NUM = $num; $m = $n;}
		}
		print STDERR "Pitch-corr : $m (", $NUM, ")\n";
		if($m) {
			for $t (@trk) {
				my ($next, $chl, $key, $vol) = @{$t};
				next if ($glb_noise && $chl==9);
				$t->[2] = (abs($key)+$m)*($key<0?-1:1);
			}
		}
	}
	
	my(%min, %max, $t, $k);	
	for $t (@trk) {
		my ($next, $chl, $key, $vol) = @{$t};
		next if $key<0 || $chl<0 || ($glb_noise && $chl==9);
		$min{$chl} = $key if !defined($min{$chl}) || $min{$chl}>$key;
		$max{$chl} = $key if $max{$chl}<$key;
	}

	my(%shift);
	for $k (keys %min) {
		my($min, $max) = ($min{$k}, $max{$k});
		print STDERR sprintf("%2d =%3d -> %-2d : ", $k, $min{$k}, $max{$k});
		
		if($min>=$nMIN && $max<=$nMAX) {
			print STDERR "ok\n";
		}
		
		if($min<$nMIN) {
			my($t);
			for($t=12;$min+$t<$nMIN; $t+=12) {}
			if($max+$t>$nMAX) {print STDERR "ko\n"; next;}
			else              {$shift{$k} = $t; print STDERR "+$t\n";}
		}
		if($max>$nMAX) {
			my($t);
			for($t=12;$max-$t>$nMAX; $t+=12) {}
			if($min-$t<$nMIN) {print STDERR "ko\n"; next;}
			else              {$shift{$k} = -$t; print STDERR "-$t\n";}
		}
	}

	for $t (@trk) {
		my ($next, $chl, $key, $vol) = @{$t};
		next if ($glb_noise && $chl==9);
		my($sgn) = $key<0?-1:1;
		$t->[2] = abs($key);
		if($shift{$chl}) {
			$t->[2] += $shift{$chl};
		} else {
			while($t->[2]<$nMIN) {$t->[2] += 12;}
			while($t->[2]>$nMAX) {$t->[2] -= 12;}
		}
		$t->[2] *= $sgn;
	}
	
	return @trk;
}

# change les BPM 
sub norm_bpm {
	my(@trk) = @_;
	
	#int(60000000/$glb_noire/$glb_period/$bpm);
	my($MAX) = 60000000/$glb_noire/($glb_period*16);
	my($MIN) = 60000000/$glb_noire/($glb_period*256);
	
	my($t, $max, $min);
	$min = $MAX;
	foreach $t (values %glb_bpm) {
		$max = $t if $t>$max;
		$min = $t if $t<$min;
	}
	print STDERR "BPM=",$min,"...",$max;
	
	my($scale) = 1;
	
	if($min<$MIN) {
		$scale = int($MIN/$min);
		$scale = int($MAX/$max) if $scale<int($MAX/$max);
		$scale = $MIN/$min if $scale==1;
	} elsif($max>$MAX) {
		$scale = 1/int($max/$MAX);
		$scale = $MAX/$max if $scale==1;
	} elsif(0 && $max<$MAX) {
		$scale = int($MAX/$max);
		$scale = $MAX/$max if $scale==1;
	} 
	if($scale!=1) {
		my(%t);
		print STDERR " x",$scale,"...";
		#$glb_ticks_per_note = int($glb_ticks_per_note*$scale);
		for $t (keys %glb_bpm) {
			$t{int($t*$scale)} = int($glb_bpm{$t}*$scale);
		}
		%glb_bpm = %t;
		for $t (@trk) {
			$t->[0] = int($t->[0]*$scale);
		}		
		print STDERR " done\n";
		
	} else {
		print STDERR "unchanged\n";
	}
	return @trk;
}

# lit un fichier midi
# retourne
# $glb_ticks_per_note = nb de ticks midi pour une noire
# %glb_tempo = map temps-midi -> tempo
# @glb_tracks = pistes 
sub read_midi {
	my($name) = @_;
	
	print STDERR "File       : ", $name, "\n";

	# open file
	open(MIDI, $midi_file=$name) || die "$name: $!, stopped";
	binmode(MIDI);

	# verif signature en-tete
	($_=&read_str(4)) eq "MThd" || die "$name: bad header ($_), stopped";
	($_=&read_long) == 6 || die "$name: bad header length ($_), stopped";

	# lecture en-tete
	my($format) = &read_short;
	my($tracks) = &read_short;
	my($delta)  = &read_short;

	print STDERR "FormatType : ", $format, "\n";
	print STDERR "#Tracks    : ", $tracks, "\n";
	print STDERR "Noire      : ", $delta, " ticks\n";
	
	$glb_ticks_per_note = $delta;

	%glb_bpm = ();
	$glb_bpm{0} = 120; # default value
	my($no, @trk);
	for($no=1; $no<=$tracks; ++$no) {
		push(@trk, &read_track($name, $no));
	}
	close(MIDI);
	
	@trk = (sort by_time @trk);
	#s&dump_midi(@trk);

	return @trk;
}

# lit une piste
sub read_track {
	my($name, $no) = @_;
	my(@track);
	
	my($z);
	($z=&read_str(4)) eq "MTrk" || die "$name: Reading track $no: bad chunk ($z), stopped";
	my($size) = &read_long(1);

	my($time) = 0;
	my($meta_event, $event) = 0;
	do {
		$time += &read_vlv;
		my($timr) = &timeround($time);
		
		$_ = &read_byte;
		if($_>=0x80) {
			$event = $_;
		} else {
			seek(MIDI, -1, 1);
		}
				
		if(&between($event, 0x80, 0x8f)) {
			# note off
			my $ch   = $event & 0xf;
			my $note = &read_byte & 0x7f;
			my $vol  = &read_byte & 0x7f;
			if (!$glb_tracks{$ch+1}) {
				$note += $glb_pitch unless $glb_noise && $ch==9;
				push(@track, [$timr, $ch, -$note-1, $vol]);
			}
		}
		if(&between($event, 0x90, 0x9f)) {
			# note on
			my $ch   = $event & 0xf;
			my $note = &read_byte & 0x7f;
			my $vol  = &read_byte & 0x7f;
			if(!$glb_tracks{$ch+1}) {
				$note += $glb_pitch unless $glb_noise && $ch==9;
				push(@track, [$timr, $ch,  $note+1, $vol]) if $vol>0;
				push(@track, [$timr, $ch, -$note-1, $vol]) if $vol==0;
			}
		}
		if(&between($event, 0xb0, 0xbf)) {
			my($code) = &read_short;
			if($code == 0x7800 || $code== 0x7B00) {
				print STDERR "mute all \n";
				#die "mute all";
				# mute all notes
				my(%set);
				for my $t (@track) {
					my ($next, $chl, $key, $vol) = @{$t};
					undef $set{$chl.",".-$key} if $key<0;
					$set{"$chl,$key"} = 1      if $key>0;
				}
				for my $k (keys %set) {
					my($ch, $note) = split(/,/,$k);
					push(@track, [$timr, $ch, -$note-1, 0]);
				}
			}
		}
		die "aftertouch" if &between($event, 0xa0, 0xaf);
		#die "pitch-bend: ".sprintf("\$%x",&read_short) if &between($event, 0xe0, 0xef);
		if(&between($event, 0xe0, 0xef)) {
			my $chl = $event & 15;
			my $bend = &read_byte;
			$bend += &read_byte<<7;
			push(@track, [$timr, -$chl-1, $bend, 0]);
			#print STDERR sprintf("pitch-bend $chl=%x\n", $bend);
		}
		if(&between($event, 0xa0, 0xaf) || 
		   #&between($event, 0xe0, 0xef) ||
		   $event == 0xf2) {&read_short;}
		if(&between($event, 0xc0, 0xdf) || 
		   $event == 0xf1 ||
		   $event == 0xf2) {&read_byte;}
		if($event == 0xff) {
			$meta_event = &read_byte;
			my $size = &read_vlv;
			if($meta_event == 0x51) {
				# set tempo
				die "bad tempo ($size)" unless $size == 3;
				my $tempo = 0; # µS par noire
				while($size--) {$tempo = ($tempo<<8) + &read_byte;}
				$glb_bpm{$timr} = int(60000000/$tempo);
			} else {
				&read_str($size);
			}
		}
	} while($event != 0xff || $meta_event != 0x2f);
	return (@track);
}

# arrondi le temps en ticks thomson
sub timeround {
	my($t) = @_;
	my($div) = $glb_ticks_per_note/0b00100000;
	return int(int($t/$div+0.5)*$div);
}

# conversion temps midi en tick thomson
sub time2tick {
	my($t) = @_;
	return int(($t*0b00100000)/$glb_ticks_per_note+0.5);
}

# affiche une piste midi à l'écran
sub dump_midi {
	my($t, $tm);
	for $t (@_) {
		my($time,$trk,$note,$vol) = @$t;
		print "(",$time-$tm,")\n";
		print sprintf("%-6d %2d %3d *%-3d", $time, $trk, $note, $vol);
		$tm = $time;
	}
	print "\n";
}

# compare les index temporels des pistes
sub cmp_trk {
	return $a->[0] <=> $b->[0];
}

# test si un valeur tombe dans un intervale
sub between {
	return $_[1] <= $_[0] && $_[0] <= $_[2];
}

# lit une chaine de n caractères depuis le fichier midi
sub read_str {
	my($t, $l);
	($l=read(MIDI, $t, $_[0]))==$_[0] || die "$midi_file: read $l when $_[0] expected: $!, stopped";
	return $t;
}

# lit 1 octet (8bits)
sub read_byte {
	return unpack("C*", &read_str(1));
}

# lit un short (16bits)	
sub read_short {
	my($a, $b) = (&read_byte, &read_byte);
	return $a*256+$b;
}

# lit un long (32bits)
sub read_long {
	my($a, $b) = (&read_short, &read_short);
	return $a*65536+$b;
}

# lit un nombre de longueur variable
sub read_vlv {
	my($n, $s, $t) = (0,0,0);
	do {
		$t = &read_byte;
		$n <<= 7; $n |= $t & 0x7f;
	} while($t & 0x80);
	return $n;
}

#!/bin/perl
# conversion de fichier midi en vfier 

# http://www.sonicspot.com/guide/midifiles.html

# no buffering
$| = 1;

&init_globals;

# frequence de base
$glb_period = 478;
	
# durée des arpèges
$glb_arpg_ticks = 0b00000001;

# décalage
$glb_pitch = undef;

# nombre de notes maxi dans un arpège
$glb_arpg_max = 2;

# utilisation du noise ?
$glb_noise = 0;

# skyline par instrument
$glb_skyline_per_inst = 0;

# volume constant
$glb_vol = undef;

$glb_nz_dk = 0.7;

# -loop <0|1|2> -track a,b,c file.mid
$file = "<missing-file>";
%glb_tracks = ();
$prev = "";
for $curr (@ARGV) {
	if(-e $curr) {$file = $curr;}
	if("-h" eq $curr) {&usage;}
	if("-p" eq $prev) {$glb_pitch = $curr;}
	if("-n" eq $prev) {$glb_arpg_max = $curr;}
	if("-i" eq $curr) {$glb_skyline_per_inst = 1;}
	if("-d" eq $curr) {$glb_noise = 1;}
	if("-v" eq $prev) {$glb_vol = $curr;}
	if("-x" eq $prev) {
		my($i, @t) = (0, split(/,/,$curr));
		foreach $i (split(/,/, $curr)) {$glb_tracks{$i} = -1;}
	}
	$prev = $curr; 
}
die "file: $file" unless -e $file;
die "loop: $loop" if $loop<0 || $loop>2;

@trk = &read_midi($file);
@trk = &norm_bpm(@trk);
@trk = &norm_inst(@trk);

@trk = &convert($glb_arpg_max, 0.5, @trk);

@tom = @trk; #&compress_track(@trk);

$file=~/.*[\/\\](.*)(\.[^\.]*)?/;
$nom = $1;
print "* $nom\n";
&print_trk(@tom);
print "* ", 1+$#tom, " octets ($nom)\n";

exit(0);


sub usage {
	print __FILE__, " [-h] [-p <pitch-offset>] [-n <MIP>] [-s] [-d] [-x <t1,t2,t3,...>] <file.mid>";
	exit(0);
}

sub convert {
	my($glb_arpg_max, $tol, @zik) = @_;

	print STDERR "Conversion...";
	
	my($nz_dk) = $glb_nz_dk;
	my($scale) = 2*16/128;
	
	# récup du tempo
	
	my($arpg) = int($glb_ticks_per_note*$glb_arpg_ticks/0b00100000 + .5);

	#my($ALG) = 2+8; #1+2;
	
	loop: for(my $restart=1; $restart; $restart = 0) {
	my(@trk, $i);
	my(%note); # notes théoriquements jouées
	my($curr, $inst, $lvol) = (0, -1, 0);  # derniere note jouée
	my($time, $next, $chl, $key, $vol);      # dernier instant
	
	# notes en cours
	my($k0, $v0, $k1, $v1);
	
	my(%lNSE);
	
	my($last_tempo) = 0;
	my(@bpm) = (sort {$a <=> $b} keys %glb_bpm);
	
	for($i=0; $i<=$#zik;) {
		($time, $chl, $key, $vol) = @{$zik[$i]};
		
		# nouveau tempo?
		if($#bpm>=0 && $bpm[0]<=$time) {
			my($tempo) = int(60000000/32/$glb_period/$glb_bpm{shift(@bpm)});
			push(@trk, 
			">TEMPO  equ    ".($last_tempo = $tempo)) if $tempo!=$last_tempo;
		}
		
		# calcule dans %note les notes jouees a l'instant $time
		do {
			#$key = $key<0?-1:1 if $glb_noise && $chl==9;
			$vol = int($vol * $scale);
			my($k) = abs($key).",$chl";
			#print "$time $chl $key $vol\n";
			if($key>0) {$note{$k} = $vol if $vol>$note{$k};} 
			else {$note{$k} = 0;}
			delete $note{$k} if $note{$k} <= 0;
			($next, $chl, $key, $vol) = @{$zik[++$i]};
		} while($time==$next && $i<=$#zik);
		
		#print "$time=[";
		#for $key (sort keys %note) {my($k,$i) = split(',', $key); ² "$glb_note{$k}($i:$k)=>$note{$key} ";}
		#print "]\n";
		
		my($delay) = &time2tick($next - $time);
				
		#print "$time=[";
		#for $key (sort keys %sp) {print "$glb_note{$key}($key)$is{$key}=>$sp{$key} ";}
		#print "]\n";
		
		my(%imp) = &important_notes($tol, %note);
		
		#print "IMP=",join(' ', sort keys %imp),"\n";

	
		# on atténue les intensité des plus vielles pour le tour suivant
		#for $key (keys %note) {
		#	$note{$key} = int($note{$key}*(.7**(($next-$time)/$glb_ticks_per_note)));
		#}
	
		#print "    [", join(' ', keys %keys), "]  $nxti\n\n";
		$xx = $v0;
		my($s) = scalar keys %imp;
		#print "X=$delay $s $nz $k0=$v0 $k1=$v1\n";
		if($s == 0) {
			push(@trk, "n0P") if $k0>0; $k0 = 0; 
			push(@trk, "n1P") if $k1>0; $k1 = 0;
		} 
		if($s == 1) {
			# si l'une des notes precedentes est conserve
			my($k) = (keys %imp);
			if($k == $k0 || $k!=$k1) {
				push(@trk, "cV0+".($v0=$imp{$k})) if $v0!=$imp{$k};
				push(@trk, "n0".$glb_note{$k0=$k}) if $k0!=$k;
				push(@trk, "n1P") if $k1>0; $k1=0;
			} else {
				push(@trk, "cV1+".($v1=$imp{$k})) if $v1!=$imp{$k};
				push(@trk, "n0P") if $k0>0; $k0=0;
			}
			$s = 0;
		} 

		my($k, $j);
		if($s>1) {
			# cas général: la fréquence la plus élevée reste sur un canal fixe
			for $j (keys %imp) {$k=$j if $j>$k;}
			if($k==$k0) {
				$j = 1;
				push(@trk, "cV0+".($v0=$imp{$k})) if $v0!=$imp{$k};
			} else {
				$j = 0;
				push(@trk, "cV1+".($v1=$imp{$k})) if $v1!=$imp{$k};
				push(@trk, "n1".$glb_note{$k1=$k}) if $k1!=$k;
			}
			delete $imp{$k}; --$s;
		}
		#print "X=$delay $s $nz $j $k0=$v0 $k1=$v1\n";
		
		my(@k) = (sort keys %imp);
		if($s==1) { #si un seul autre
			$k = shift(@k);
			push(@trk, "cV0+".($v0=$imp{$k})) if $j==0 && $v0!=$imp{$k};
			push(@trk, "cV1+".($v1=$imp{$k})) if $j==1 && $v1!=$imp{$k};
			push(@trk, "n0".$glb_note{$k0=$k}) if $j==0 && $k0!=$k;
			push(@trk, "n1".$glb_note{$k1=$k}) if $j==1 && $k1!=$k;
			--$s;
		}
		
		# percussions non interruptives mais ayant la priorité 
		my($nz) = 0;
		my($min_z) = 1000;
		while(my ($k, $v) = each %note) {
			my($z,$i) = split(',', $k);
			next if $i!=9;
			$min_z = $z if $z<$min_z;
 			$nz += $v*$v if $glb_noise;
		}
		
		# TODO prévoir un volume tunable pour le noise
		$nz = int(sqrt($nz)*$scale*6); #int(sqrt($nz)*$scale*4);
		$nz = ($nz+15)&~15; 
		$nz = 47 if $nz>47;
		
		if($v0 + $v1 + $nz > 63) {
			$scale = int($scale*63/($v0 + $v1 + $nz)*128)/128;
			print STDERR "rescale ", int(128*$scale),"/128...";
			goto loop;
		}
				
		# optim: mise en facteur des effets "bruits"

		#push(@trk, " x set $delay");
		#$nz &= ~1;
		#print STDERR "$min_z\n" if $nz;
		if($s==0 && $nz>0) {
			my($li, $lo);
			
			$nz_dk = $glb_nz_dk**($min_z / 36);
			#$nz_dk = 0.9 if $min_z == 38;
			#$nz_dk = 0.1 if $min_z == 36;
			$nz_dk = 0.99 if $nz_dk>0.99;
			
			my($dur) = 0;
			for(my $t = $nz; $t>0 && $delay>0; ++$dur) {$t = int($t*$nz_dk);--$delay;}
			
			$delay += $dur;
			while($nz>0 && $delay>0) {
				push(@trk, "cNZ+$nz", "cTK");
				$nz=int($nz*$nz_dk);
				--$delay;
			}
			push(@trk, "cNZ+0", ("cTK") x $delay);
				
			$delay = $nz = 0;
		}

		# =======================
		push(@trk, "cNOISE+$nz") if $nz>0;
		my($x)=0;
		while(($s>0||$nz>0) && $delay>0) { # tremolo
			if($s>0) {
				$k = $k[$x++]; $x=0 if $x>$#k;
				push(@trk, "cVOL0+".($v0=$imp{$k})) if $j==0 && $v0!=$imp{$k};
				push(@trk, "cVOL1+".($v1=$imp{$k})) if $j==1 && $v1!=$imp{$k};
				push(@trk, "n0".$glb_note{$k0=$k}) if $j==0 && $k0!=$k;
				push(@trk, "n1".$glb_note{$k1=$k}) if $j==1 && $k1!=$k;
			}
			if($nz>0) {
				$nz = int($nz*$nz_dk);
				# optim orig
				$nz = 0 if ($nz<$v0/2 || $nz<$v1/2 || $delay==0);
				push(@trk, "cNOISE+$nz");
			}
			push(@trk, "cTK"); --$delay;
		}
		#print join(' ', @trk[$#trk-4...$#trk]), "\n";
		
		#die if $xx==63 && $v0==62;
		
		push(@trk, "cNZ+".($nz=0)) if $nz>0; # inutile?
		push(@trk, ("cTK")x$delay);
		
		#print "$inst $curr\n";
	}
	push(@trk, "n0P") if $k0>0; $k0 = 0; 
	push(@trk, "n1P") if $k1>0; $k1 = 0;
	
	print STDERR "done\n";
	
	return @trk;
	}
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

sub freq2note {
        my($f) = int($_[0]);
        my($n) = $glb_freq2note{$f};
        if(!defined $n) {
                my($d) = 1000000;
                for(my $i=0; $i<=$glb_max_note; ++$i) {
                        my($t) = $f - &freq($i);
                        $t = -$t if $t<0;
                        if($t<$d) {$d = $t; $n = $i;}
                }
                $glb_freq2note{$f} = $n;
        }
        return $n;
}

sub freq {
        my($key) = @_;
        my($f) = $glb_freq{$key};
        $glb_freq{$key} = $f = int(440*(2**(($key-69.0)/12))) unless defined $f;
        return $f;
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

sub dist_to_set {
        my($key, @keys) = @_;

        my($m, $k) = 10000;
        for $k (@keys) {
                my $d = $k - $key;
                $d = -$d if $d<0;
                $m = $d if $d<$m;
        }

        return $m;
}

sub by_time {
	my($time1, $ch1, $note1, $vol1) = @$a;
	my($time2, $ch2, $note2, $vol2) = @$b;
	
	#$note1 = -$note1 if $note1<0;
	#$note2 = -$note2 if $note2<0;
	
	my($d) = $time1 <=> $time2;
	#$d = abs($note1)<=>abs($note2) unless $d;
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

# comprime les s128 s128 en s64 etc
sub compress_sXX {
	my(@t) = @_;
	my($i, $d, $s, @r);
	
	my(%m);	while(my ($k, $v) = each %glb_duree) {$m{$v} = $k;}
	
	for $i (@t) {
		if($i=~/^s(\d+)/) {
			die "durée inconnue: $i" unless defined $m{$i};
			$s += $m{$i};
		} else {
			while($s>0) {
				for $d (@glb_duree) {
					if($s>=$d) {
						$s -= $d;
						push(@r, "$glb_duree{$d}");
						last;
					}
				}
			}
			push(@r, $i);
		}
	}
	print STDERR "sXX(",1+$#r,")...";	
	return (@r);
}

sub compress_track {
	my(@t) = @_;
	return @t if 0;
	
	print STDERR "Compression(",1+$#t,")...";
	
	@t = compress_sXX(@t);
	#@t = compress_LZ(@t);
	#@t = compress_rpt(@t);
	@t = compress_SAM(@t);
	
	if(0) {
	@t = compress_SAM(("sA")x2,("sA","sB")x48,("sA")x2);
	
	}
		
	my($do) = 0;
	while(1) {
		my($l)=1+$#t;
		print STDERR "($l)...";
		@t = &compress_track_aux(@t);
		last if 1+$#t == $l;
	}
	
	if(0) {
		#@t = (("cB", ("cA")x8)x2, "cD")x2;#@t = @t[0..256];
		my($lbl,$l) = "l00";
		do {
			$l = 1+$#t;	
			print STDERR "$l...";
			@t = &comp($lbl++, @t);
		} while($l!=1+$#t);
		#print STDERR "\n";
	}

	
	print STDERR "(",1+$#t,")...done\n";
	return @t;
}

sub expand_code {
	my(@in) = @_;
	my(@out);
	
	# lookup label
	my(%lbl);
	for my $i (0..$#in) {
		$lbl{$1} = $i+1 if $in[$i]=~/([^\s]*)\s*set\s*[*]/;
	}

	# virtually execute the score, but record notes
	my(@out, @for, @jsr);
	for(my $i=0; $i<=$#in;) {
		my $c = $in[$i++];
		#print STDERR "$i     $c\n";
		if($c=~/.*\sset\s/) {
			# ignore
		} elsif($c=~/cRPT1\+(\d+)/) {
			unshift(@for, $1, $i);
			push(@out, "$c,$1=$i") if $DBG;
		} elsif($c=~/cNXT/) {
			push(@out, "$c,$for[0]=$i") if $DBG;
			if($for[0]-->0) {
				$i = $for[1];
			} else {
				shift(@for); 
				shift(@for);
			}
		} elsif($c=~/cJMP/) {
			$in[$i] =~ /(.*)<-8/;
			$i = $lbl{$1};
			last unless defined $i;
			push(@out, "$c,$1=$i") if $DBG;
		} elsif($c=~/cJSR/) {
			$in[$i] =~ /(.*)<-8/;
			unshift(@jsr, $i+2);
			$i = $lbl{$1};
			push(@out, "$i $c,$1 : ".join(',', @jsr)) if $DBG;
		} elsif($c=~/cRTS/) {
			$i = shift(@jsr);
			push(@out, "$i $c ".$in[$i-1]." : " . join(',', @jsr)) if $DBG;
		} else {
			push(@out, $c);
		}
	}
	
	die "for not empty" if @for;
	die "jsr not empty" if @jsr;
	#print STDERR "input:",1+$#in," expanded:",1+$#out;

	return @out;
}

# regroupe les codes en mots atomiques
sub group_atomic {
	my(@d);
	for my $s (@_) {
		if($s =~ /^[scn]/ || $s =~ /\sset\s/) {push(@d, $s);}
		else {$d[$#d] .= ",$s";}
	}
	return @d;
}

# taille d'un code en octet
sub code_size {
	my($l, @in) = (0, @_);
	for my $s (@in) {$l += scalar split(/,/, $s) unless $s=~/\sset\s/;}
	return $l;
}

sub compress_SAM {
	local(@data) = &group_atomic(&expand_code(@_));
	
	#$DBG = 1;
	
	my($in) = join("\n", &expand_code(split(/,/, join(',', @data))));
	
	print STDERR "SAM";
	
	while(1) {
		print STDERR "(",&code_size(@data),")...";
		#for my $i (@data) {print "$i\n";}
	
		# ajout du semaphore
		push(@data, "--END--");
		
		#print STDERR "sam(",$#data,")...";
	
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
			
			# un prefix doit contenir cRPT1 et cNXT
			my($for) = 0;
			for(my $j=0; $j<$len;++$j) {
				++$for if $data[$deb+$j]=~/cRPT1/;
				--$for if $data[$deb+$j]eq"cNXT";
				$len = $j if $for<0;
			}
			while($for>0) {
				--$len;
				--$for if $data[$deb+$len]=~/cRPT1/;
				++$for if $data[$deb+$len]eq"cNXT";
			}
			next unless $len; undef $for;
		
			# taille du code local
			my($k) = join(',',@data[$deb..$deb+$len-1]);
			my($cz) = scalar split(/,/, $k); 

			# saute si trop petit
			next if $cz<=3;
				
			# saute si déjà traité
			next if $last eq $k; $last = $k; 
			#next if $done{$k}; $done{$k} = 1; undef $k;
			
			#print STDERR "\n$i:$len $k";
		
			# trouve les répétitions
			my(@o) = &occurs($deb, $len, $i, \@t, \@d);
			
			# gain possible
			my($gain) = $cz*($#o+1) - ($cz + 1);
			++$gain if $data[$deb+$len-1]=~/cJMP/;
			for(my $j=0; $j<=$#o; ++$j) {
				my($c) = 0;
				while($j<$#o && $o[$j+1]-$o[$j]==$len) {++$j; ++$c;}
				if($c>0) {$gain -= 2 + 3;} else {$gain -= 3;}
			}
			
			# saute si aucun gain
			next if $gain<=0;
			
			#next if $gain<$min;
			#if($gain>$max) {$max = $gain; $min = $max>>1;}
			
			#print STDERR "$gain (o=$#o, cz=$cz): $k\n";
			#$gain = $#o+1;
			
			#print STDERR "o=$#o, $cz, $gain\n";
			
			#print STDERR "$zz * ",(1+$#o), "=$z: $k\n";
			$gain{$i} = $gain;
			#$xgain{$i} = ($data[$deb+$len-1]=~/c(JSR|JMP|RTS)/);
			
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
		
			my($used) = 0;
			for my $o (@o) {for my $j (0..$len-1) {$used |= $alloc[$j+$o];}}
			next if $used;
			
			for my $o (@o) {
				for my $j (0..$len-1) {$alloc[$j+$o] = 2*($i+1);}
				$alloc[$o] |= 1;
			}
			
			my(@code) = @data[$deb...$deb+$len-1];
				
			#print STDERR "<<<<<\n", join("\n", @code),">>>>>\n\n";
				
			pop(@code) if $code[$#code]=~/cRTS/;
			if($code[$#code]=~/c(JSR|JMP)/) {
				$code[$#code]=~s/cJSR/cJMP/;
			} else {
				push(@code, "cRTS");
			}
				
			#print STDERR join("\n", @code),"\n\n";
				
			$lbl{$i} = &tmp_lbl;
			#die if $lbl{$i}=~/[^\d]34$/;
			push(@lib, sprintf("%-6s set    *", $lbl{$i}), @code);
		}
		undef %precalc;
		print STDERR ".score";
	
		# generation du code
		my(@out);
		for(my $j=0; $j<$#data;) {
			#print STDERR $j," ",$alloc[$j]&1," ",($alloc[$j]>>1)-1," ",$data[$j],"\n";
			if(!$alloc[$j]) {
				if($data[$j] eq "cRTS" && $out[$#out]=~/cJSR/) {
					$out[$#out]=~s/cJSR/cJMP/;
				} else {
					push(@out, $data[$j]);
				}
				++$j;
			} elsif($alloc[$j] & 1) {
				my($i) = $alloc[$j]>>1;
				my($lbl) = $lbl{$i-1};
				if($lbl=~/37$/) {
				}
				# boucle for ?
				my($c) = 0;
				while(($alloc[++$j]>>1)==$i) {++$c if ($alloc[$j]&1);}
				if($c>0) {
					push(@out, "cRPT1+$c");
					push(@out, "cJSR,$lbl<-8,$lbl&255");
					push(@out, "cNXT");
				} else {
					my($jmp) = $data[$j-1]=~/c(RTS|JMP)/?"cJMP":"cJSR";
					
					#print "ZZZZZZZZZZZZZ ",$data[$j-1] if $lbl =~ /[^\d]61$/;
					# XXX JMP si le label se termine par RTS
					push(@out, "$jmp,$lbl<-8,$lbl&255");
				}
			} else {++$j;}
		}
		
		#@lib = ("sIN: $cpt", @lib, "sOUT: $cpt");
		# adjonction de la bibliothèque
		if($out[$#out] =~ /\sset\s/) {
			splice(@out, $#out, 0, @lib);
		} else {
			my($lbl) = &tmp_lbl;
			push(@out, "cJMP,$lbl<-8,$lbl&255");
			push(@out, @lib);
			push(@out, sprintf("%-6s set    *", $lbl));
		}
		
		# elimination des jmp vers jmp
		for(my $i=0; $i<$#out; ++$i) {
			next unless $out[$i]=~/([^\s]+)\s+set\s/;
			my($l1) = "$1<-8,$1&255";
			next unless $out[$i+1]=~/cJMP,([^\s]+)<-8/;
			#	print STDERR "\n",$out[$i],"\n",$out[$i+1],"\n";
			my($l2) = "$1<-8,$1&255";
			splice(@out,$i,2,());
			#print STDERR "$l1 -> $l2";
			for($i=$#out;$i>=0;--$i) {
				$out[$i] =~ s/$l1/$l2/;
			}
		}
		
		@data = @out;
		
		my($out) = join("\n", &expand_code(split(/,/, join(',', @data[0..$#data-1]))));
		
		#open(OUT, ">out".(++$cpt));
		#print STDERR ">$cpt<";
		#print OUT $out;
		#$DBG = 1;
		#print OUT join("\n", &expand_code(split(/,/, join(',', @data[0..$#data-1]))));
		#$DBG = 0;
		#for my $s (@data) {
		#	print OUT "\tfcb\t" if $s!~/ set /;
		#	print OUT "$s\n";
		#}
		#close(OUT);
		
		my(@a) = split(/\n/, $in);
		my(@b) = split(/\n/, $out);
		
		if($#a!=$#b) {
			$DBG = 1;
			print STDERR "$in\nXXXXXXXXXXXXXXXX\n".join("\n", &expand_code(split(/,/, join(',', @data[0..$#data-1]))));
			die "$#a $#b";
		}
		for(my $i=0; $i<=$#a;++$i) {die "$i: $a[$i]!=$b[$i]" if $a[$i] ne $b[$i];}
		die "IN\n$in\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx\nOUT\n$out\n" unless $in eq $out;
	}
		
	pop(@data);
	@data = &reorg_lib(@data);
	
	#print "in: $in\n";
	#print "out: $out\n";
	
	return split(/,/, join(',', @data));
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

sub reorg_lib {
	my(@in) = @_;
	my(%lbl, %gto, $l);
	for my $i (0..$#in-1) {
		$lbl{$l=$1} = $i if $in[$i]=~/([^\s]+)\s+set/;
		$gto{$l} = $1 if defined($l) && $in[$i]=~/cJMP,(.*)<-8/;
	}
	my(%todo, @lib) = %lbl;
	for(my @t = keys %todo; $#t>=0; @t = keys %todo) {
		my($i, $maxl, $maxi);
		for $i (@t) {
			$l = 0;
			for(my $j=$i; defined($j) && $todo{$j}; $j = $gto{$j}) {++$l;}
			#print STDERR "q$i : $l\n";
			if($l>$maxl) {$maxl = $l;$maxi = $i;}
		}
		for($i = $maxi; defined($i) && $todo{$i}; $i=$gto{$i}) {
			delete $todo{$i};
			$l = $lbl{$i};
			do {
				#print STDERR $l,":",$in[$l],"\n";
				push(@lib, $in[$l]);
			} while($in[++$l]!~/c(RTS|JMP)/);
		}
		push(@lib, $in[$l]);
		#print STDERR "XXXX\n";
	}
	my($lib) = 0; while($lib<=$#in && $in[$lib++]!~/cJMP/) {}
	splice(@in, $lib, $#in-$lib, @lib);
	return @in;
}

# essai: tentative à base de LZ(W,78)
sub compress_LZ {
	my(@in) = @_;
	my(@data, @r);
	
	for my $i (&expand_code(@in[0..$#_])) {
	#for my $i (@_) {
		if(0 && $i =~ /^s\d+/ && $data[$#data] =~ /cNOISE/) {$data[$#data] .= ",$i";} 
		elsif($#data>=0 && $data[$#data]=~/cNOISE,/ && $i=~/$cNOISE/) {$data[$#data]=$i;}
		elsif($i =~ /^[scn]/ || $i =~ / set /) {push(@data, $i);}
		else {$data[$#data] .= ",$i";}
	}

	my($start) = "--START--";
	push(@data, $start);
	
	# detecte les procédures
	for(my $i=0; 0 && $i<=$#in;++$i) {
		my $s = $in[$i];
		if($s =~ /i\d+\sset\s+\*/i) {
			my(@p);
			while(($s = $in[++$i]) !~ /rts/i) {
				if($s =~ /^[scn]/) {push(@p, $s);} else {$p[$#p] .= ",$s";}
			}
			#print STDERR join(' ', @p),"\n";
			for my $j (0..$#p) {push(@data, @p[$j..$#p]);}
			push(@data, "c".rnd);
		}
	}
	
	#@data=@data[0..$#data/4];
	#push(@data, @data, @data, @data, @data);
	
	#for(my ($l,$i)=($#data,$#data-6); $i<$l; ++$i) {push(@data, @data[$i..$l]);}
	
	#return &expand_code(@_);
	
	#@data = (("sA", "sB", "sC")x20);
	
	#for my $i (@data) {
	#	print "$i\n";
	#}
	
	my($lbl) = &tmp_lbl;
	
	# 1ere etape: compression LZ
	my($w, %D, @c, @C, @L);
	$D{$w = ""} = $C[0] = 0;
	push(@c, 0, "<empty>");
	for my $i (reverse @data) {
		my $t = $w.",".$i;
		my $l = $D{$t};
		
		if(defined $l) {$w = $t;}
		else {
			#print $t,"\n";
			my $n = scalar keys %D;
			if(1 || $n<10000) {
				$L[$D{$t} = $n] = (scalar split(/,/, $t))-1;
				$C[$n] = 0;
			}
			$n = $D{$w} + 0;
			$C[$n] = 1;
			
			push(@c, $n, $i);
			$w = "";
		}
	}

	for my $i (0..$#C) {
		$C[$i] = 0 if $L[$i]<=4;
	}
	
	# TODO: mettre à jour les C[$i] via les used transitifs
	
	for my $i (0..$#c/2) {
		print sprintf("%4d\t%4d %14s (%4d) ...%d...\n", $i, $C[$i], $c[$i*2+1], $c[$i*2], $L[$i]);
	}	
	
	my($lbl, @r) = $glb_lbl; #&tmp_lbl;
	
	push(@r, "cJMP", "${lbl}_<-8", "${lbl}_&255");
	# BIBLIOTHEQUE;;; ON prend la sequence la plus longue
	my(%todo); for my $i (1..$#c/2) {$todo{$i} = 1 if $C[$i];}
	for(my @t = keys %todo; $#t>=0; @t = keys %todo) {
		my($i, $maxl, $maxi);
		for $i (@t) {
			my($l) = 0;
			for(my $j=$i; $j>0 && $todo{$j}; $j = $c[$j*2]) {++$l;}
			if($l>$maxl) {
			$maxl = $l;
				$maxi = $i;
			}
		}
		for($i = $maxi; $i>0 && $todo{$i}; $i=$c[$i*2]) {
			push(@r, sprintf("%-6s set    *", "${lbl}$i"));
			push(@r, split(/,/,$c[$i*2+1]));
			delete $todo{$i};
		}
		if($i>0) {
			if(!$C[$i]) {
				while($i>0) {
					push(@r,split(/,/,$c[$i*2+1]));
					$i = $c[$i*2];
				}
			} else {
				push(@r, "cJMP", "$lbl$i<-8", "$lbl$i&255");
			}
		}
		push(@r, "cRTS") unless $i>0;
	}
	
	push(@r, sprintf("%-6s set    *", "${lbl}_"));
	
	
	for my $i (reverse 1..$#c/2) {
		while($i>0 && $C[$i]==0) {
			push(@r,split(/,/, $c[$i*2+1]));
			$i = $c[$i*2];
		}
		push(@r, "cJSR", "$lbl$i<-8", "$lbl$i&255") if $i>0 && $C[$i];
	}
	
	
	my($z) = 0;
	for my $i (@r) {++$z unless $i=~/ set /;}
	print STDERR "lz($z)";
	
	return @r;
	&print_trk(@r);
	
	exit;
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
#	return ($i==$#data ? +1 : $j==$#data ? -1 : $data[$i] cmp $data[$j]);
}

sub valid {
	my($i, $l) = @_;
	return 0 unless $l;
	return 0 unless $data[$i]=~/^[scn]/;
	for(my $j=0; $j<$l; ++$j) {
		return 0 if $data[$j]=~/cNXT/;
		last if $data[$j]=~/cRPT/;
	}
	return 1;
}

sub compress_track_aux {
	my(@track) = @_;
	my(@compr);
	
	return @_ if 0;
	
	my($len) = $#track;
	my($i, $k, $p, $n, $m, $t, $g);
	
	# optim. carte chaine => liste d'occurrence
	my(%occur);
	for($i=0; $i<=$len; ++$i) {
		my($s) = $track[$i];
		my($l) = $occur{$s};
		$occur{$s} = $l = [] unless defined $l;
		push(@$l, $i);
	}
	
	# compression
	for($i=0; $i<=$len;) {
		$n = 0; $g = 0;
		$m = ($len-$i)>>1;
		
		if(1) {
			# optimized way about 50% faster
			my($l) = $occur{$track[$i]};
			do {$k = shift(@$l);} while($k!=$i && @$l);
			#print $track[$i]," ",$i,"=>", join(',', @$l), "\n";
			for $k (@$l) {
				last if $k-$i>$m;
				$t = &compress_rep_count($i, $k-$i, \@track);
				#print "rep=$t ", $k-$i, "\n" if $t;
				my($gg) = $t*($k-$i); #push(@compr, "=$gg i=$i t=$t l=".($k-$i));
				if($gg>$g && $t<64) {$g = $gg; $n = $t; $p = $k-$i;}
				#print $n, " => ", $p, "\n";
			}
		} else {
			for($k=1; $k<=$m; ++$k) {
				$t = &compress_rep_count($i, $k, \@track);
				if($t>=$n && $t<64) {$n = $t; $p = $k;}
			}
		}
		
		#print "i=$i n=$n p=$p ", join(',', @track[$i .. $i+$p-1]), "\n" if $n>0;
		if($n>0 && $p>3 || $n>2 || $n*$p>2) {
			#print "*\n";
			push(@compr, "cRPT1+$n", @track[$i .. $i+$p-1], "cNXT");
			$i += $p*($n+1);
		} else {
			push(@compr, $track[$i++]);
		}
	}
	#print "in: ", $#track, " out: ", $#compr, "\n";
	
	return @compr;
}

sub compress_rep_count {
	my($i, $l, $tab) = @_;
	#print "$i ($l) -->";
	my($s, $m, $e) = ($i, $#{$tab}, 1);
	return 0 if $tab->[$i]=~/^[0-9]+/;
	while($i+$l<=$m && $tab->[$i] eq $tab->[$i+$l]) {
		$e = 0 if $tab->[$i] =~ /cRPT1/;
		last if $e && $tab->[$i] =~ /cNXT/;
		++$i;
	}
	#print "$i ", $tab->[$i],"!=",$tab->[$i+$l], "\n";
	return int(($i-$s)/$l);
}

# traduit une duree
sub convert_duree {
	my($duree) = @_;

	my($d, @r);
	
	my($z, $Z) = 10000;
	
	#print "duree=$duree : ";
	for $d (@glb_duree) {
		my($t) = $duree - $d;
		$t = -$t if $t<0;
		if($t < $z) {
			$z = $t;
			$Z = $d;
		}
	}
	
	$last_off = 0;
#	return () if  $last_duree == $Z;
#	$last_duree = $Z;
	print "over: $z\n" if $z & 0;
	return ("$glb_duree{$Z}");
}

# traduit une duree
sub convert_duree_orig {
	my($note, $duree) = @_;
	my($d, @r);
	
	return @r if $duree<$glb_min_duree;
	
	#print "duree=$duree : ";
	do {
		for $d (@glb_duree) {
			if($duree>=$d) {
				$duree -= $d;
				push(@r, "$note+$glb_duree{$d}");
				last;
			}
		}
	} while(1 && $duree>=$glb_min_duree);
	
	return @r;
}

# initialise les variables globales
sub init_globals {
	my($i, $o, $n) = 12;
	
	# construction du mapping des notes midi -> format track
	%glb_note = ();
	foreach $o (0 .. 7) {
		foreach $n ("C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B") {
			$glb_note{++$i} = "$n$o";
		}
	}
	$glb_max_note = $i;
	$glb_max_freq = &freq($i);
	
	%glb_duree = (
	0b11110000 => "s1ddd",
	0b11100000 => "s1dd",
	0b11000000 => "s1d",
	0b10000000 => "s1",
	0b01111000 => "s2ddd",
	0b01110000 => "s2dd",
	0b01100000 => "s2d",
	0b01000000 => "s2",
	0b00111100 => "s4ddd",
	0b00111000 => "s4dd",
	0b00110000 => "s4d",
	0b00100000 => "s4",
	0b00011110 => "s8ddd",
	0b00011100 => "s8dd",
	0b00011000 => "s8d",
	0b00010000 => "s8",
	0b00001111 => "s16ddd",
	0b00001110 => "s16dd",
	0b00001100 => "s16d",
	0b00001000 => "s16",
	0b00000111 => "s32dd",
	0b00000110 => "s32d",
	0b00000100 => "s32",
	0b00000011 => "s64d",
	0b00000010 => "s64",
	0b00000001 => "s128");
	@glb_duree = (sort {$b <=> $a} keys %glb_duree); # valeur décroissante
	$glb_max_duree = $glb_duree[0];
	$glb_max_code  = $glb_duree{$glb_max_duree};
	$glb_min_duree = $glb_duree[$#glb_duree];
}

# tous les instruments doivent être entre C1(24) et C5(72)
sub norm_inst {
	my(@trk) = @_;
	
	my($C1, $C5) = (25, 72);
	my($nMIN, $nMAX) = ($C1, $C5);
	
	if(!defined $glb_pitch) {
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
		next if $key<0 || ($glb_noise && $chl==9);
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
	my($MAX) = 60000000/32/$glb_period/16;
	my($MIN) = 60000000/32/$glb_period/240;
	
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
	} elsif($min>$MIN) {
		$scale = int($min/$MIN);
		$scale = $min/$MIN if $scale==1;
	} 
	$scale = 2;
	if($scale!=1) {
	        $glb_nz_dk = $glb_nz_dk**$scale;
		my(%t);
		print STDERR " /",$scale,"...";
		#$glb_ticks_per_note = int($glb_ticks_per_note*$scale);
		for $t (keys %glb_bpm) {
			$t{int($t/$scale)} = int($glb_bpm{$t}/$scale);
		}
		%glb_bpm = %t;
		for $t (@trk) {
			$t->[0] = int($t->[0]/$scale);
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
	#&dump_midi(@trk);

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
		if(&between($event, 0xa0, 0xbf) || 
		   &between($event, 0xe0, 0xef) ||
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

sub time2tick_n {
	my($t) = @_;
	return 0 unless $t;
	$t = int(($t*0b00100000)/$glb_ticks_per_note+0.5);
	$t = $glb_min_duree if $t<$glb_min_duree;
	return $t;
}

# affiche une ligne de note à l'écran
sub flush_line {
	print "       fcb    $glb_line\n" if length($glb_line)>0;
	$glb_line = "";
}

# ajoute une note à la ligne courante
sub add_note {
	my($note) = @_;
	return if length($note)==0;
	
	if($note=~/^cEXE/) {
		&flush_line;
		$glb_line = $note;
		return;
	}
	
	if($note=~s/^>//) {
		&flush_line;
		print "$note\n";
		return;
	}
	
	my($len) = length($glb_line);
	
	++$len if $len>0;
	$len += length($note);
	
	&flush_line if $len>=40-16;
	
	$glb_line .= "," if length($glb_line)>0;
	$glb_line .= $note;
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

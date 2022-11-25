#!/bin/perl
# conversion de fichier midi en vfier 

# http://www.sonicspot.com/guide/midifiles.html

&init_globals;

# durée des arpèges
$glb_arpg_ticks = 0b00000001;

# décalage
$glb_pitch = 0;

# nombre de notes maxi dans un arpège
$glb_arpg_max = 1;

# -loop <0|1|2> -track a,b,c file.mid
$file = "<missing-file>";
%glb_order = ();
$prev = "";
for $curr (@ARGV) {
	if(-e $curr) {$file = $curr;}
	if("-h" eq $curr) {&usage;}
	if("-t" eq $prev) {
		my($i, @t) = (0, split(/,/,$curr));
		$glb_order{-1} = -1;
		for($i=0; $i<=$#t; ++$i) {$glb_order{$t[$i]} = $i};
	}
	$prev = $curr; 
}
die "file: $file" unless -e $file;
die "loop: $loop" if $loop<0 || $loop>2;

&read_midi($file);
&max_bpm;

if(!%glb_order) {
	my(@col_t) = &collision_time;
	
	my($t, $i, %weight);
	# analyse
	for($i=0; $i<=$#glb_tracks; ++$i) {
		my(@w) = @{$glb_tracks[$i]};
#		next unless &is_track_mono(\@w);
		@w = (&track_comp(@w), -$col_t[$i], &track_weights(@w));
		$weight{$i} = \@w if $#w>0;
	}
	my(@t) = sort {
		my @w1 = @{$weight{$a}}; my @w2 = @{$weight{$b}}; my $d = 0;
		for(my $i=0; $i<=$#w1 && $d==0; ++$i) {$d = $w1[$i]<=>$w2[$i];}
		$d;
	} keys %weight;
	%glb_order = (-1 => -1); $i=0;
	for $t (@t) {
		$glb_order{$t} = $i++;
		print sprintf("Track %2d ", $t), join(' ', @{$weight{$t}}), "\n";
	}
	
	print "Trying with option -t ", join(',', @t), "\n";
}

# les pistes sont rendues mono, ajoutées les unes aux autres 
# et le résultat final est rendu mono
if(0) {
@trk = ();
for $t (keys %glb_order) {
	next if $t<0;
	#print $t," $#trk\n";
	my(@t) = @{$glb_tracks[$t]};
	@t = &make_mono($glb_arpg_max, .7, @t); # unless &is_track_mono(\@t);
	push(@trk, @t);
	#@trk = sort by_time @trk;#	@trk = &make_mono(@trk);
	#&dump_midi(@trk);
	#@trk = &merge_mono(@trk);
}
@trk = sort by_time @trk;
@trk = &make_mono($glb_arpg_max, .1, @trk);
#@trk = &merge_mono(@trk);
}

# chaque piste est rendue mono et sont mergées avec une
# priorité sur les pistes.
if(0) {
@trk = ();
for $t (keys %glb_order) {
	next if $t<0;
	#print $t," $#trk\n";
	my(@t) = @{$glb_tracks[$t]};
	@t = &make_mono($glb_arpg_max, @t); # unless &is_track_mono(\@t);
	push(@trk, @t);
	@trk = sort by_time @trk;
#	@trk = &make_mono(@trk);
	#&dump_midi(@trk);
	@trk = &merge_mono(@trk);
}
#@trk = sort by_time @trk;
#@trk = &make_mono(@trk);
#@trk = &merge_mono(@trk);
}

$ALG = 0;

# toutes les pistes ensembles sont rendues mono
#for $file (<STDIN>) {
#print "$file...\n";
#&read_midi($file);
if(1) {
@trk = ();
for $t (keys %glb_order) {
	next if $t<0;
	#print $t," $#trk\n";
	my(@t) = @{$glb_tracks[$t]};
	#@t = &make_mono(@t); # unless &is_track_mono(\@t);
	push(@trk, @t);
	#@trk = sort by_time @trk;
#	@trk = &make_mono(@trk);
	#&dump_midi(@trk);
	#@trk = &merge_mono(@trk);
}
@trk = sort by_time @trk;
#&dump_midi(@trk);

my($best, $bALG) = 1e10;
for($ALG=0; 0 && $ALG<63; ++$ALG) {
	#next if ($ALG & 24);
	next if ($ALG & 4) && ($ALG & 24);
	my(@z) = &make_mono($glb_arpg_max, 0.5, @trk);
	@z = &convert_track(\@z);
	@z =  &compress_track(@z);
	$stat{$ALG} += $#z;
	
	print "$ALG=$#z\n";
	if($#z<$best) {
		$bALG = $ALG;
		$best = $#z;
	}
}
#}
$ALG = $bALG*0+1+2+8; $ALG=43;
@trk = &make_mono($glb_arpg_max, 0.5, @trk);
print "ALG=$ALG\n";
}

#print "\n\n";
#for $k (keys %stat) {$tats{$stat{$k}} = $k;}
#for $k (sort {$a<=>$b} keys %tats) {
#	print sprintf("%6d => %d\n", $tats{$k}, $k);
#}
#exit;

#@trk = &make_mono($glb_arpg_max, 0.5, @trk);
@tom = &convert_track(\@trk);
@tom = &compress_track(@tom);

$file=~/.*\/(.*)\.mid/;
print "* $1\n";
&flush_line;
for $n (@tom) {&add_note($n);}
&flush_line;
print "* ", 1+$#tom, " octets\n";

exit(0);
	
# calcul du temps de collision par piste
sub collision_time {
	my(@trk, $n, $i, $j, $k);
	
	for $i (@glb_tracks) {++$n; push(@trk, @$i);}
	@trk = sort by_time @trk;
	
	my(@count, @col_t, $delta_t, $time, $ch, $note, $delta);
	@count = (0) x $n;
	@col_t = (0) x $n;
	
	do {
		do {
			($time, $ch, $note) = @{$trk[$i++]};
			$count[$ch] += $note>0?1:-1;
			$delta_t = $i<=$#trk ? $trk[$i][0]-$time : 0;
		} while($delta_t==0 && $i<=$#trk);
	
		$delta = 0;
		for($j=0; $j<$n; ++$j) {$delta += $count[$j]>0?$delta_t:0;}
		for($j=0; $j<$n; ++$j) {$col_t[$j] += $delta if $count[$j]>0;}
		
		#print sprintf("%6d ", $time);
		#for($j=0; $j<$n;++$j) {print $col_t[$j],"\t";}
		#print "\ncount\t";
		#for($j=0; $j<$n;++$j) {print sprintf("%2d", $count[$j]);}
		#print "\n";
	} while($i<=$#trk);
	
	return @col_t;
}

sub track_comp {
	my(@t) = @_;
	@t = &merge_mono(@t);
	@t = &compress_track("Loop1", @t);
	return $#t;
}

# poids pour comparer les pistes par ordre d'importance
sub track_weights {
	my(@track) = @_;
	
	# 1er poids: la hauteur moyenne
	# 2eme poids: le temps avec du son
	# 3eme poids: taille compressée
	my($t, $n, $x, $p);
	for $t (@track) {
		my($time, $ch, $note) = @$t;

		$p+=$note<0?-$time:$time;
		$x+=$note<0?-$note:$note;
		++$n;
	}
	return () unless $n;
	return (int($x/$n/12), $p/$n);
}

sub make_mono {
	my($glb_arpg_max, $tol, @zik) = @_;
	
	#my($ALG) = 2+8; #1+2;
	
	my(@res, $i);
	my(%note); # notes théoriquements jouées
	my($curr, $inst, $lvol) = (0, -1, 0);  # derniere note jouée
	my($time, $next, $trk, $key, $vol);      # dernier instant
	
	my($arpg) = int($glb_ticks_per_note*$glb_arpg_ticks/0b00100000 + .5);
	
	for($i=0; $i<=$#zik;) {
		($time, $trk, $key, $vol) = @{$zik[$i]};
		do {
#			print "$tim $key $vol ($note{$key}  ",$vol{"$trk,".-$key},")\n";
			my($k);
			if($key>0) {$note{$k="$key,$trk"} = $vol;} 
			else {$key = -$key; $note{$k="$key,$trk"} = 0;}
			delete $note{$k} if $note{$k} <= 0;
			($next, $trk, $key, $vol) = @{$zik[++$i]};
		} while($time==$next && $i<=$#zik);
		
		#print "$time=[";
		#for $key (sort keys %note) {my($k,$i) = split(',', $key); print "$glb_note{$k}($i:$k)=>$note{$key} ";}
		#print "]\n";
		
		# on conserve les notes les plus elevées par instrument
		if($ALG & 1) {
		for $key (keys %note) {
			my($k,$i) = split(',', $key); 
			while(--$k>=0) {delete $note{"$k,$i"};}
		}
		}
		
		# calcul du spectre
		my(%sp);
		while(($key, $vol) = each %note) {
			my($k,$i) = split(',', $key);
			$sp{$k} = $vol if $sp{$k}<$vol;
		}
		#for $key (keys %sp) {$sp{$key} = int(sqrt($sp{$key}));}
		
		# note max
		#my($max) = 0;
		#for $vol (values %note) {$max = $vol if $vol>$max;}
		
		# on atténue les intensité des plus vielles pour le tour suivant
		#for $key (keys %note) {
		#	$note{$key} = int($note{$key}*(.7**(($next-$time)/$glb_ticks_per_note)));
		#}
		
		#while(($key, $vol) = each %sp) {
		#	my(%z) = &spectrum($key, $vol);
		#	while(my($k, $v) = each %z) {$sp{$k} += $v if $sp{$k};}
		#}
				
		# on efface les sous-fréquence
		if($ALG & 2) {
		for $key (keys %sp) {
			my($f, $g) = &freq($key);
			if(!($ALG & 32)) {
			for $g (2 .. 9) {my($t) = &freq2note($f/$g); delete $sp{$t}; delete $is{$t};}
			} else {
			for($f=$key; ($f-=12)>=0;) {delete $sp{$f};}
			}
		}}
		
		#print "$time=[";
		#for $key (sort keys %sp) {print "$glb_note{$key}($key)$is{$key}=>$sp{$key} ";}
		#print "]\n";
		
		%keys = ();
		my($nxti) = 1;
		if(scalar keys %sp<=1) {
			# 0 ou 1 note
			%keys = %sp;
		} else  {
			# plusieurs notes.
			my($c, $dm, $km, @nt) = (0, 0);
			
			# note max
			$max = 0;
			foreach $vol (values %sp) {$max = $vol if $vol>$max;}
			$max *= $tol;
			
			while($c<$glb_arpg_max && $max>1 && scalar keys %sp>0) {
				@nt = ();
				while(($key, $vol) = each %sp) {
				#print "$key => $vol ($max)\n";
				push(@nt,$key) if $vol>=$max;}
				#print "x    [", join(' ', sort {$a<=>$b} @nt), "]\n";
				if($#nt<0) {
					$max = int($tol*$max);
					#last;
				} else {
					$dm = 0; $km = -1;
					for $key (@nt) {
						my($d) = &dist_to_set($key, keys %keys);
						#print "k=$key d=$d\n";
						next if $d<12 && ($ALG & 4);
						next if $c>0 && $d>=12 && ($ALG & 8);
						next if $c>0 && $d>=24 && ($ALG & 16);
						if($d>$dm || $d==$dm && $key>$km) {
							$dm = $d; 
							$km = $key;
						}
					}
					if($km>=0) {
						++$c;
						$keys{$km} = $sp{$km};
						delete $sp{$km}
					} else {
						$max = int($tol*$max);
					}
				}
			}
		}
		
		#print "    [", join(' ', keys %keys), "]  $nxti\n\n";
		
		my($s) = scalar keys %keys;
		if(0 == $s) {	
			# 0 note: silence
			push(@res, [$time, $inst, -$curr, $lvol]) if $curr!=0;
			#print "$time -$curr\n" if $curr!=0;
			($curr, $inst, $lvol) = (0, -1, 0);
		} elsif(1 == $s) {
			# 1 note: meme qu'avant ==> rien, sinon pause + on
			my($note) = (%keys);
			if($note != $curr) {
				push(@res, [$time, $inst, -$curr, $lvol]) if $curr!=0;
				($curr, $inst, $lvol) = ($note, $nxti, $keys{$note});
				push(@res, [$time, $inst, $curr, $lvol]);
				#print "$time -$curr\n" if $curr!=0;
				#print "$time $note\n";
			} else {
				($curr, $inst, $lvol) = ($note, $nxti, $keys{$note});
			}
		} else {
			# accord
			my(@t) = sort {$a<=>$b} keys %keys;
			my($min, $max) = ($t[0], $t[$#t]);
			
			while($time+$arpg<=$next) {				
				#print "$time -$curr\n" if $curr!=0;
				push(@res, [$time, $inst, -$curr, $lvol]) if $curr!=0;
				# on trouve la note suivante
				while(!defined $keys{++$curr}) {$curr = $min-1 if $curr>=$max;}
				($curr, $inst, $lvol) = ($curr, $nxti, $keys{$note});
				#print "$time $curr\n";
				push(@res, [$time, $inst, $curr, $lvol]);
				$time += $arpg;
			} 
		}
		#print "$inst $curr\n";
	}
	push(@res, [$time, $inst, -$curr, $lvol]) if $curr!=0;
	#&dump_midi(@res);
	return @res;
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

sub spectrum_dist1 {
	my($key, %keys) = @_;
	my($k);
	my(%z) = &spectrum($key, 100);
	for $k (keys %z) {delete $keys{$k};}
	my($d) = 0;
	for $k (keys %keys) {++$d;}
	return $d;
}


sub spectrum_dist2 {
	my($key, %keys) = @_;
	my($k);
	my(%z) = &spectrum($key, 100);
	for $k (keys %z) {$keys{$k} -= $keys{$key};}
	my($d) = 0;
	for $k (keys %keys) {$d += $keys{$k}**2;}
	return $d;
}

sub spectrum_dist {
	my($key, %keys) = @_;
	my($k);
	my(%z) = &spectrum($key, 100);
	for $k (keys %z) {delete $keys{$k};}
	my($d) = 0;
	for $k (keys %keys) {$d += $keys{$k}**2;}
	return $d;
}


# calcule le spectre d'une note
sub spectrum {
	my($key, $vol) = @_;
	my(%vol, $m);
	
	my($f) = &freq($key);

	$vol{$key}    += $vol; #&ampl($vol, $f);
	#foreach $m (2, 3, 4, 5, 6, 7) {
	foreach $m (3, 5, 7, 9) {
		last if $f*$m>$glb_max_freq;
		$vol{&freq2note($f*$m)} += &ampl($vol/$m, $f*$m);
	}
	return %vol;
}

sub ampl {
	my($vol, $f) = @_;
	
	#return int($vol);
	
	my($o) = abs(&freq2note($f)/12 - 7) + 1;
	
	return int($vol/sqrt($o));
}

sub merge_mono {
	my(@res, $i, $j);
	
	my($time, $ntime, $trk, $note);
	my(@curr) = (-1, -1); # note effectivement jouée
	my(@notes);           # notes théoriquement jouees
	
	for($i=0; $i<=$#_;) {
		($time, $trk, $note) = @{$_[$i]};
		#print "$time $note\n";
		do {
			# nouvelle note
			if($note>0) {
				push(@notes, $trk, $note);
			} else {
				for($j=0; $j<$#notes; $j+=2) {
					splice(@notes, $j, 2) if $notes[$j]==$trk && $notes[$j+1]+$note==0;
				}
			}
			($ntim, $trk, $note) = @{$_[++$i]};
			#print "$ntim $note ", join(',', @notes), "\n";
		} while($time==$ntim && $i<=$#_);
		
		# detection de la note la plus forte
		my(@best) = (-1, -1);
		for($j=0; $j<$#notes; $j+=2) {
			my($t, $n) = @notes[$j..$j+1];
			my($d) = $glb_order{$t} - $glb_order{$best[0]};
			#if($d==0) {$d = $t>$best[0] || $n>=$best[1] ? 1 : 0;}
			if($d==0) {$d = $n>$best[1];}
			@best = ($t, $n) if $d>0;
		}
		
		# debug
		if(0) {  
			print sprintf("notes: t=%-6d %-4s ", $time, $glb_note{$best[1]});
			for($j=0; $j<$#notes; $j+=2) {
				my($b) = $notes[$j]==$best[0] && $notes[$j+1]==$best[1];
				print $b?"(":" ";
				print $notes[$j]," ",$notes[$j+1];
				print $b?")":" ";
				print "  ";
			}
			print "\n";
		}
		
		# si changement
		if($best[1] != $curr[1]) {
			push(@res, [$time, $curr[0], -$curr[1]]) if $curr[1]>0;
			push(@res, [$time, $best[0],  $best[1]]) if $best[1]>0;
			@curr = @best;
			#print "####\n";
		}
	}
	
	#&dump_midi(@res);
	
	return @res;
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

sub usage {
	print __FILE__, " [-h] [-l <0|1|2>] -t <t1,t2,t3,...> <file.mid>";
	exit(0);
}

sub compress_track {
	my(@t) = &compress_track_aux("I", 0, @_);
	@t = &compress_track_aux("J", 0, @t);
	@t = &compress_track_aux("K", 1, @t);
	return @t;
}

sub compress_track_aux {
	my($loopCode, $shortMode, @track) = @_;
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
				if($gg>$g && $t<($shortMode?7:31)) {$g = $gg; $n = $t; $p = $k-$i;}
				#print $n, " => ", $p, "\n";
			}
		} else {
			for($k=1; $k<=$m; ++$k) {
				$t = &compress_rep_count($i, $k, \@track);
				if($t>=$n && $t<31) {$n = $t; $p = $k;}
			}
		}
		
		#print "i=$i n=$n p=$p ", join(',', @track[$i .. $i+$p-1]), "\n" if $n>0;
		if($n>0 && $p>3 || $n>2 || $n*$p>2) {
			#print "*\n";
			push(@compr, "cFor${loopCode}+".($n+1), @track[$i .. $i+$p-1], "cNxt${loopCode}");
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
	while($i+$l<=$m && $tab->[$i] eq $tab->[$i+$l]) {
		$e = 0 if $tab->[$i] =~ /cFor/;
		last if $e && $tab->[$i] =~ /cNxt/;
		++$i;
	}
	#print "$i ", $tab->[$i],"!=",$tab->[$i+$l], "\n";
	return int(($i-$s)/$l);
}

# converti une piste mono au format thomson
sub convert_track {
	my($track) = @_;
	
	$last_duree = $last_off = 0;
	
	# récup du tempo
	my(@bpm) = (sort {$a <=> $b} keys %glb_bpm);
	
	my($len) = $#{$track};
	my($i, @trk) = 0;
	
	#print "!! $len\n";
	
	while($i+1<=$len) {
		my($time1, $ch1, $note1) = @{$track->[$i++]}; 
		#print $time1, " ", $ch1," ", $note1,"\n";
		next unless $note1>0;
		my($time2, $ch2, $note2) = @{$track->[$i++]};
		
		# nouveau tempo?
		push(@trk, "cBPM,".$glb_bpm{shift(@bpm)}) if $#bpm>=0 && $bpm[0]<=$time1;
		
		#print "* $time1 $time2 ", &time2tick($time2-$time1), "\n";
		
		my($tick1) = &time2tick($time1);
		my($tick2) = &time2tick($time2);
		
		# cas spécial des silences au début				
		# ignoré: push(@trk, &convert_note("nP", 0, $tick1)) if $i==2 && $tick1>0;
		
		# a-t-on une note après celle ci ?
		my($tick3) = $tick2;
		my($zzz);
		if($i<=$len) {
			# oui, séquence: note, pause
			my($time3, $ch3, $note3) = @{$track->[$i]};
			$tick3 = &time2tick($zzz=$time3);
		}
		#my(@z) = &convert_note($glb_note{$note1}, $tick2-$tick1, $tick3-$tick2);
		my(@z) = &convert_note($glb_note{$note1}, &time2tick_n($time2-$time1), &time2tick($zzz-$time2));
		#print "$time1=", join(',', @z), "\n";
		push(@trk, @z);		
	}	

	push(@trk, "cEnd");
	
	#print join(',', @trk);
	
	return @trk;
}

#converti un temps en une série de note
sub convert_note {
	my($note, $duree_on, $duree_off) = @_;
	
	$duree_off = 0 if $duree_off < 0;
	my($dbg) = 0;
	print "convert_note: $note, $duree_on, $duree_off..." if $dbg;
	
	if($duree_on >= $glb_max_duree) {
		return (&convert_duree($glb_max_duree), $note, &convert_note($note, $duree_on - $glb_max_duree, $duree_off));
	}
	if($duree_off >= $glb_max_duree) {
		return (&convert_note($note, $duree_on, $duree_off - $glb_max_duree), &convert_duree($glb_max_duree), $note);
	}
	
	# même base que précédement
	if($duree_on + $duree_off == $last_duree) {
		if($duree_off == $last_off) {
			print "$note\n" if $dbg;
			# note similaire
			return ($note);
		} if($duree_on == 0) {
			$last_off = 0;
			# pause
			print "nP\n" if $dbg;
			return ("nP");
		} if(int(($duree_off/$last_duree)*16)==0) {
			# pas de staccato ou trop court
			$last_off = 0;
			print "$note\n" if $dbg;
			return ($note);
		} else {
			# staccato
			my($r) = int(($duree_off/$last_duree)*16);
			$last_off = $duree_off;
			print "STAC_+$r,$note\n" if $dbg;
			return ("STAC_+$r", $note);
		}
	} else {
		my(@t);
		push(@t, &convert_duree($duree_on), $note) if $duree_on>=$glb_min_duree;
		push(@t, &convert_duree($duree_off), "nP") if $duree_off>=$glb_min_duree;
		print join(",", @t),"\n" if $dbg;
		return @t;
	}
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
	return () if  $last_duree == $Z;
	$last_duree = $Z;
	print "over: $z\n" if $z & 0;
	return ("$glb_duree{$Z}");
}

sub convert_note_orig {
	my($note, $duree_on, $duree_off) = @_;
	#$duree_on &= ~1; $duree_off &= ~1;
	
	#print "cn: $note, ${duree_on}, ${duree_off}\n";
	
	if($duree_on==0) {
		# un silence
		if($duree_off>=$glb_max_duree) {
			return ("nP+$glb_max_code", &convert_note($note, $duree_on, $duree_off-$glb_max_duree));
		} else {
			return &convert_duree("nP", $duree_off);
		}
	} elsif($duree_off==0) {
		# note sans silence
		if($duree_on>=$glb_max_duree) {
			return ("$note+$glb_max_code", &convert_note($note, $duree_on-$glb_max_duree, 0));
		} else {
			return &convert_duree($note, $duree_on);
		}
	} elsif($duree_on>=$glb_max_duree) {
		# note plus longue que la note la plus longue
		return ("$note+$glb_max_code", &convert_note($note, $duree_on-$glb_max_duree, $duree_off));
	} elsif($duree_off>=$glb_max_duree) {
		return (&convert_note($note, $duree_on, $duree_off-$glb_max_duree), "nP+$glb_max_code");
	} else {
		# note normale
		my(@r) = (&convert_note($note, $duree_on, 0), &convert_note(0, 0, $duree_off));
		return @r;
		
		# optimisation avec des staccato
		my($d, $s);
		for $d (@glb_duree) {
			for $s (1, 7) {
				my($t) = ($s * $d)/8;
				if($t==$duree_on) {
					my($stac) = $s==1?"STACC":"STAC";
					my($toff) = $duree_off + ($d - $t);
					my(@t) = ("$note+$glb_duree{$d}+$stac", &convert_note($note, 0, $toff));
					@r = @t if $#t<$#r;
				}
			}
		}
		return @r;
	}
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
	$glb_freq{$key} = $f = int(440*(2**(($key-70.0)/12))) unless defined $f;
	return $f;
}

# initialise les variables globales
sub init_globals {
	my($i, $o, $n) = 12;
	
	# construction du mapping des notes midi -> format track
	%glb_note = ();
	foreach $o (0 .. 7) {
		foreach $n ("C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B") {
			$glb_note{++$i} = "n$n$o";
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

# change les BPM 
sub max_bpm {
	my($MAX) = 228;
	my($t, $max);
	foreach $t (values %glb_bpm) {
		$max = $t if $t>$max;
	}
	print "Max BPM=",$max,"...";
	my($scale) = $max<$MAX?int($MAX/$max):1/int($max/$MAX);
	$scale = $MAX/$max if $max>$MAX && $scale==1;
	if($scale!=1) {
		my(%t);
		print "changing to ", int($max*$scale), "...";
		#$glb_ticks_per_note = int($glb_ticks_per_note*$scale);
		for $t (keys %glb_bpm) {
			$t{int($t*$scale)} = int($glb_bpm{$t}*$scale);
		}
		%glb_bpm = %t;
		for $t (@glb_tracks) {
			my($l);
			foreach $l (@$t) {
				$l->[0] = int($l->[0]*$scale);
			}
		}		
		print "done\n";
		
	} else {
		print "unchanged\n";
	}
}

# lit un fichier midi
# retourne
# $glb_ticks_per_note = nb de ticks midi pour une noire
# %glb_tempo = map temps-midi -> tempo
# @glb_tracks = pistes 
sub read_midi {
	my($name) = @_;
	
	print "File       : ", $name, "\n";

	# open file
	open(MIDI, $name) || die "$name: $!, stopped";
	binmode(MIDI);

	# verif signature en-tete
	($_=&read_str(4)) eq "MThd" || die "$name: bad header ($_), stopped";
	($_=&read_long) == 6 || die "$name: bad header length ($_), stopped";

	# lecture en-tete
	my($format) = &read_short;
	my($tracks) = &read_short;
	my($delta)  = &read_short;

	print "FormatType : ", $format, "\n";
	print "#Tracks    : ", $tracks, "\n";
	print "Noire      : ", $delta, " ticks\n";
	
	$glb_ticks_per_note = $delta;

	%glb_bpm = ();
	$glb_bpm{0} = 120; # default value
	@glb_tracks = ();
	while($#glb_tracks+1 < $tracks) {
		my($no) = 1+$#glb_tracks;
		print "Lecture piste ", $no, "...";
		my($track, @channels) = &read_track($name, $no);
		push(@glb_tracks, $track);
		if(@channels) {
			if(&is_track_mono($track)) {
				print "mono";
			} else {
				print "poly";
			}
			print " (", join(',', @channels), ")";
		}
		print "\n";
	}
	close(MIDI);
}

# lit une piste
sub read_track {
	my($name, $no) = @_;
	my(@track, %channels);
	
	($_=&read_str(4)) eq "MTrk" || die "$name: bad chunk ($_), stopped";
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
			$note += $glb_pitch;
			push(@track, [$timr, $ch, -$note-1, $vol]);
			$channels{$ch+1} = 1;
		}
		if(&between($event, 0x90, 0x9f)) {
			# note on
			my $ch   = $event & 0xf;
			my $note = &read_byte & 0x7f;
			my $vol  = &read_byte & 0x7f;
			$note += $glb_pitch;
			push(@track, [$timr, $ch,  $note+1, $vol]) if $vol>0;
			push(@track, [$timr, $ch, -$note-1, $vol]) if $vol==0;
			$channels{$ch+1} = 1;
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
	return (\@track, sort keys %channels);
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


# teste qu'une piste est mono. Cela revient à avoir
# un on/off on/off
sub is_track_mono {
	my($track) = @_;
	
	my($i) = 0;
	while($i<=$#{$track}-1) {
		my($tick1, $ch1, $tone1, $vol1) = @{$track->[$i++]};
		my($tick2, $ch2, $tone2, $vol2) = @{$track->[$i++]};
		return 0 if $tone1+$tone2!=0 || $ch1!=$ch2;
	}
	return $i>0;
}

# retourne les canaux de la piste
sub track_channels {
	my($t, %ch);
	for $t (@_) {
		my($tick1, $ch1, $tone1) = @{$t->[$i++]};
		$ch{$ch1} = 1;
	}
	return sort keys %ch;
}

sub track_avg_note {
	my($t, $n, $x);
	for $t (@_) {
		my($tick1, $ch1, $tone1, $vol1) = @{$t->[$i++]};
		$x+=$tone1<0?-$tone1:$tone1;
		++$n;
	}
	return $x/$n;
}


# affiche une ligne de note à l'écran
sub flush_line {
	print "\tfcb\t$glb_line\n" if length($glb_line)>0;
	$glb_line = "";
}

# ajoute une note à la ligne courante
sub add_note {
	my($note) = @_;
	
	if($note=~/^c/) {
		$note =~ s/Loop/Lp/;
		&flush_line;
		$glb_line = $note;
		&flush_line;
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
	my($t);
	read(MIDI, $t, $_[0])==$_[0] || die "$midi_file: can't read: $!, stopped";
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

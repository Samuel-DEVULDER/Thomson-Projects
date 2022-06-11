#/bin/perl

#use Graphics::MagickXX;
use Image::Magick;

$SIG{'INT'} = 'DEFAULT';
$SIG{'CHLD'} = 'IGNORE';

# suppression du buffer pour l'affichage en sortie
#$| = 1;

# variables globale
$glb_magick = Image::Magick->new;
$glb_to7pal = 2;       # 2 = palette TO7, 1 = TO7/70, 0 = TO9
$glb_maxcol = $glb_to7pal>1?8:16;      # nb total de couls
$glb_lab    = 0;       # distance couleur cielab
$glb_dith   = 0;       # avec 3 ca donne des images pas mal colorées!
$glb_gamma  = 2.20; #1/0.45;
$glb_clean  = 0.2;
    
# error dispersion matrix. Index represents:
#    X 3
#  0 1 2
@glb_err = (0.000, 0.000, 0.000, 0.000) if 1;     # no dith
@glb_err = (0.200, 0.700, 0.100, 0.000) if 0;     # nice lines
@glb_err = (0.062, 0.312, 0.187, 0.437) if 0;     # floyd steinberg
@glb_err = (0.187, 0.312, 0.062, 0.437) if 1;     # floyd steinberg
@glb_err = (0.000, 0.500, 0.000, 0.500) if 0;     # simple
@glb_err = (0.000, 1.000, 0.000, 0.000) if 0;
@glb_err = (0.100, 0.500, 0.100, 0.300) if 0;
@glb_err = (0.300, 0.500, 0.100, 0.100) if 0;
@glb_err = (0.250, 0.500, 0.125, 0.125) if 0;
@glb_err = (0.500, 0.000, 0.500, 0.000) if 0;     # motifs inca
@glb_err = (0.200, 0.500, 0.100, 0.200) if 0;     # motifs inca
@glb_err = (0.000, 0.400, 0.400, 0.200) if 0;     # motifs inca
@glb_err = (0.250, 0.250, 0.000, 0.500) if 0;     # sierra 2-4a
@glb_err = (0.333, 0.334, 0.000, 0.333) if 0;
@glb_err = (0.233, 0.333, 0.234, 0.200) if 0;     # à voir
@glb_err = (0.233, 0.367, 0.200, 0.200) if 1*0;     # à voir

@glb_err = (0.250, 0.500, 0.250, 0.000) if 0;

@glb_err = (0.200, 0.233, 0.367, 0.200) if 0;     # serpente
@glb_err = (0.250, 0.500, 0.250, 0.000) if 0;

@glb_err = (0.100, 0.500, 0.000, 0.400) if 0;     # simple (horiz)
@glb_err = (0.025, 0.125, 0.050, 0.125) if 0;     # permet d'avoir des plages de couleurs constantes . Ca rend plutot pas mal pour les jeux videos.
@glb_err = (0.050, 0.125, 0.050, 0.125) if 0;     # permet d'avoir des plages de couleurs constantes . Ca rend plutot pas mal pour les jeux videos.
@glb_err = (0.100, 0.150, 0.050, 0.200) if 0;     # fs attenue (pas mal pour les jeux)
@glb_err = (0.125, 0.250, 0.125, 0.250) if 0;     # modified atkinson

@mat = (
    [ 0,48,12,60, 3,51,15,63],
    [32,16,44,28,35,19,47,31],
    [ 8,56, 4,52,11,59, 7,55],
    [40,24,36,20,43,27,39,23],
    [ 2,50,14,62, 1,49,13,61],
    [34,18,46,30,33,17,45,29],
    [10,58, 6,54, 9,57, 5,53],
    [42,26,38,22,41,25,37,21]);

$mat_y = 1+$#mat;
$mat_x = 1+$#{$mat[0]};
$max = 0;
for $y (0..$mat_y-1) {
  for $x (0..$mat_x-1) {
    ++$mat[$y][$x];
    $max = $mat[$y][$x] if $mat[$y][$x]>$max;
  }
}
for $y (0..$mat_y-1) {
  for $x (0..$mat_x-1) {
    $mat[$y][$x] /= $max;
  }
}
    
# construit les maps pour la multiplication
for($i = -256; $i<256; ++$i) {$glb_map0[$i & 0x1ff] = xint($i * $glb_err[0]) & 0x1ff;}
for($i = -256; $i<256; ++$i) {$glb_map1[$i & 0x1ff] = xint($i * $glb_err[1]) & 0x1ff;}
for($i = -256; $i<256; ++$i) {$glb_map2[$i & 0x1ff] = xint($i * $glb_err[2]) & 0x1ff;}
for($i = -256; $i<256; ++$i) {$glb_map3[$i & 0x1ff] = xint($i * $glb_err[3]) & 0x1ff;}
for($i = -256; $i<256; ++$i) {$glb_sqr [$i & 0x1ff] = $i * $i;}
$glb_err0 = $glb_err[0]>0;
$glb_err1 = $glb_err[1]>0;
$glb_err2 = $glb_err[2]>0;
$glb_err3 = $glb_err[3]>0;

# limit error
$clamp = -48;
for($i = -256; $i<256; ++$i) {$glb_clamp[$i & 0x1ff] = ($i< $clamp ? $clamp : $i) & 0x1ff;}

# map une intensité entre 0..255 vers l'intensité produite par le circuit EFxxx le plus proche (16 valeurs)
@ef_vals = (0, 39, 74, 101, 122, 140, 157, 171, 185, 195, 206, 216, 227, 237, 248, 255) if 1;

# eval perso
@ef_vals = (0,78,116,138,157,171,182,187,205,215,222,229,238,244,249,255) if 0;
@ef_vals = (0,51,91,117,142,161,172,187,199,210,220,227,236,244,248,255) if 1;

# ef TEO
@ef_vals = (0, 100, 127, 142, 163, 179, 191,203, 215, 223, 231, 239, 243, 247, 251, 255) if 1;
@ef_vals = (0, 127, 169, 188, 198, 205, 212, 219, 223, 227, 232, 239, 243, 247, 251, 255) if 0; # eval prehisto
@ef_vals = (0, 174, 192, 203, 211, 218, 224, 229, 233, 237, 240, 244, 247, 249, 252, 255) if 0; # prehisto 2
@ef_vals = (0, 169, 188, 200, 209, 216, 222, 227, 232, 236, 239, 243, 246, 249, 252, 255) if 0; # prehisto 3
@ef_vals = (0, 153, 175, 189, 199, 207, 215, 221, 227, 232, 236, 241, 245, 248, 252, 255) if 0; # prehisto 4

@intens = @ef_vals;
#@intens = (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 218, 224, 240, 255);
#@intens = (0, 66, 96, 120, 138, 153, 168, 180, 192, 201, 210, 219, 228, 237, 246, 252);
#@intens = (0, 32, 66, 98, 128, 152, 170, 185, 200, 212, 224, 233, 245, 255);
#@intens = (0, 60, 98, 128, 152, 170, 185, 200, 212, 224, 233, 245, 255);
@intens = (0, 32, 64, 96, 128, 160, 192, 255) if 0;
@intens = (0, 16, 32, 48, 64, 96, 128, 160, 192, 224, 255) if 0;
@intens = (0, 32, 64, 128, 255) if 0;
@intens = (0, 50, 100, 200, 255) if 0; ## <== pas mal
@intens = (0, 32, 64, 128, 192, 255) if 0;
@intens = (0, 33, 66, 99, 133, 166, 200, 255) if 0;
@intens = (0, 98, 128, 152, 170, 
    185, #200, 
    212, #224, 
    233, #241, 
    251) if 0;
@intens = (0, 45, 98, 185, 255) if 0;
@intens = (0, 16, 32, 64, 128, 192, 224, 240, 255) if 0; ##   
@intens = (0, 32, 64, 128, 192, 224, 255) if 0;
@intens = (0, 16, 32, 64, 128, 255) if 0;

# basse luminosité
@intens = (0, 39, 74, 122, 195, 227, 255) if 0; # ajustement aux niveaux thomson
@intens = (0, 39, 74, 122, 195, 227, 248) if 0; # ajustement aux niveaux thomson
@intens = (0, 39, 101, 195, 255) if 0;
@intens = (0, 39, 74, 122, 185, 216, 255) if 0; # ajustement aux niveaux thomson

# 0 64 128 192 256~
# 0 32 64 96 128 160 192 224 256
@intens = (0, 78, 116, 138, 157, 187, 222, 238, 255) if 0;
@intens = (0, 78, 116, 157, 195, 222, 255) if 0;
@intens = (0, 78, 138, 222, 255) if 0;
@intens = (0, 78, 138, 157, 255) if 0;
@intens = (0, 78, 157, 244) if 0;
@intens = (0, 138, 255) if 0;
@intens = (0, 51, 91, 117, 161, 187, 227, 255) if 0;
@intens = (0, 42, 84, 126, 168, 210, 255) if 0;
@intens = (0, 51, 102, 153, 204, 255) if 0;
@intens = (0, 16, 32, 64, 128, 192, 224, 240, 255) if 0;
@intens = (0, 100, 127, 142, 179, 215, 255) if 0;

# equi reparti
@intens = (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 255) if 0;
@intens = (0, 32, 64, 96, 128, 160, 192, 224, 255) if 0;
@intens = (0, 48, 96, 144, 192, 255) if 0;

if($glb_gamma) {
	#print join(",", @intens), "\n";
	foreach (@intens)  {$_ = &gamma($_);}
	#print join(",", @intens), "\n";
	foreach (@ef_vals) {$_ = &gamma($_);}
}

# remap des intens
for($i=0; $i<=$#intens; ++$i) {
    my($z) = 0;
    for($j=0, $m=1e30; $j<=$#ef_vals; ++$j) {
        next if $ef_vals[$j]<0; 
        $k = $intens[$i] - $ef_vals[$j]; $k = -$k if $k<0;
        if($k<$m) {$m=$k; $z = $ef_vals[$j];}
    }
    $intens[$i] = $z;
}

# mapping des intensités
@map_ef = ();
for($i=0; $i<256; ++$i) {   
    for($j=0, $m=1e30; $j<=$#intens; ++$j) {
        next if $intens[$j]<0; 
        $k = $i - $intens[$j]; $k = -$k if $k<0;
        if($k<$m) {$m=$k; $map_ef[$i] = $intens[$j];}
    }
    for($j=0; $j<=$#intens && $intens[$j]<=$i; ++$j) {
        next if $intens[$j]<0; 
        $map_ef2[$i] = $intens[$j];
    }
}
#@map_ef = ();


# analyse des fichiers en argments
@files = @ARGV;

# si aucun fichier, alors on les prends depuis l'entrée standard
if(!@files) {
	while(<>) {
		chomp;
		next if /chlgdls/;
		y%\\%/%;
		s%^([\S]):%/cygdrive/$1%;
		push(@files, $_);
	}
}

# extension supportées
$supported_ext = "\.(gif|pnm|png|jpg|jpeg|ps)";
# fichier a effacer pour stopper le prog
$stopme = ".stop_me";
open(f, ">$stopme"); close(f);

# &start_wd;

# traitement de tous les fichiers
$cpt = 0;
foreach $in (@files) {
	last if ! -e "$stopme";
	next unless $in =~ /$supported_ext$/i;

	++$cpt;

	next if $in eq "-";
	#next if $in =~ /ord/;
	next if $in =~ /6846/;

	$out = $in; $out=~s/$supported_ext$/.gif/i; $out=~s/.*[\/\\]//;
	$out = "x$out";

	print $cpt,"/",1+$#files," $in => $out\n";
	
	&reset_wd;
	
	#next if -e $out;

	# lecture
	my(@px) = &read_image($in);	
	
	@px = &cleanup(@px) if 1;
	
	# creation palette 16 couls (passage par une globale pour simplifier le code)
	@glb_pal = &find_palette($glb_maxcol, @px);
	
	#&print_pal(@glb_pal);

	# precalc distance entre les couleurs de la palette
	$glb_dist = ();
	for($i=0; $i<$glb_maxcol; ++$i) {
		$glb_dist[$i + $i*$glb_maxcol] = 0;
		for($j = 0; $j<$i; ++$j) {
			$glb_dist[$j + $i*$glb_maxcol] = $glb_dist[$i + $j*$glb_maxcol] = &irgb_dist($glb_pal[$i], $glb_pal[$j]);
		}
	}
    
	if(0) {
		$px[1] = &rgb2irgb(1,1,1);
		$px[2] = &rgb2irgb(1,1,1);
		$px[3] = &rgb2irgb(1,1,1);
		$px[321] = &rgb2irgb(1,1,1);
		$px[322] = &rgb2irgb(1,1,1);
		$px[323] = &rgb2irgb(1,1,1);
	}
    
	if(0) {
		# pour tester : dither sans contrainte
		my(@p2) = @px;
		for($p=$y=0; $y<200; ++$y) {
			for($x=0; $x<320; ++$x) {
				$p = 320*$y+$x;
				my($rvb) = $p2[$p] = &irgb_map($p2[$p], \@glb_clamp);
				for($i=0, $dm=1e30; $i<$glb_maxcol; ++$i) {
					$d  = &irgb_dist($rvb, $glb_pal[$i]);
					print &irgb2hex($glb_pal[$i]), " $i => $d\n" if 0;
					if($d<$dm) {$dm = $d; $p2[$p] = $glb_pal[$i];}
				}
				print "$x,$y : ", &irgb2hex($rvb), "=>", &irgb2hex($p2[$p]), " $dm\n\n" if 0;
				$rvb = &irgb_sub($rvb, $p2[$p]);
				#print " /_\\ = ", &irgb2hex($rvb), "\n";
				$p2[$p + 319] = &irgb_add($p2[$p + 319], &irgb_map($rvb, \@glb_map0)) if $glb_err0 && $y<199 && $x>0;
				$p2[$p + 320] = &irgb_add($p2[$p + 320], &irgb_map($rvb, \@glb_map1)) if $glb_err1 && $y<199;
				$p2[$p + 321] = &irgb_add($p2[$p + 321], &irgb_map($rvb, \@glb_map2)) if $glb_err2 && $y<199 && $x<319;
				$p2[$p + 001] = &irgb_add($p2[$p + 001], &irgb_map($rvb, \@glb_map3)) if $glb_err3 &&           $x<319;
			}
		}
		&write_image("${out}.gif", @p2);
	}
  
	# process image
	my($p, $y, $x) = (0,0,0);
	for($y=0; $y<200; ++$y) {
        print "\r> ", int($y/2), "%  ";
		for($x=0; $x<320; $x+=8) {
			$p = $y * 320 + $x;
			#for($i=0; $i<8; ++$i) {$px[$p+$i] = &irgb_map($px[$p+$i], \@glb_clamp);}
			for($i=0; $i<8; ++$i) {$px[$p+$i] = &irgb_sat($px[$p+$i]);}
			my($forme, $fond) = &couple6(@px[$p..$p+7]);	
			#print "===> ", &irgb2hex($forme), " ", &irgb2hex($fond),"\n";
			for($i=0; $i<8; ++$i, ++$p) {
				my($rvb) = &irgb_sat($px[$p]);
				#$rvb = &irgb_add($rvb, &rgb2irgb(rand(0.02),rand(0.02),rand(0.02))) if 0; #($i+$y) & 8;
				# meilleur couleur approchante
				$px[$p] = (&irgb_dist($forme, $rvb) < &irgb_dist($fond, $rvb)) ? $forme : $fond;
				#print $i,"::", &irgb2hex($rvb),"=>",&irgb2hex($px[$p]),"\n";
				#for($dm = 1e30, $k = 0; $k<$glb_maxcol; ++$k) {if(($d = &irgb_dist($rvb, $glb_pal[$k])) < $dm) {$dm = $d; $px[$p] = $glb_pal[$k];}};
                
				#if(($px[$p] & 0xff) > 0x40) {
				#    print &irgb2hex($px[$p]),"\n", &irgb2hex($rvb), " f=", &irgb2hex($forme), ":", &irgb_dist($forme, $rvb)," F=", &irgb2hex($fond),":",&irgb_dist($fond,$rvb),"\n";
				#}
				#if(($px[$p] & 0xff) < 0x80) {
				#    print &irgb2hex($px[$p]),"\n", &irgb2hex($rvb), " f=", &irgb2hex($forme), ":", &irgb_dist($forme, $rvb)," F=", &irgb2hex($fond),":",&irgb_dist($fond,$rvb),"\n";
				#}
                
				# diffusion d'erreur
				if(1) {
					#print " p=",&irgb2hex($rvb);
					$rvb = &irgb_sub($rvb, $px[$p]);
					#print " q=", &irgb2hex($px[$p]), " d=", &irgb2hex($rvb);
					#print " m=", irgb2hex(&irgb_map($rvb, \@glb_map1)), " n=", &irgb2hex($px[$p+320]), " X=", &irgb2hex(&irgb_uadd($px[$p + 320], &irgb_map($rvb, \@glb_map1))), "\n";
					$px[$p + 319] = &irgb_add($px[$p + 319], &irgb_map($rvb, \@glb_map0)) if $glb_err0 && $y<199 && ($x+$i)>0;
					$px[$p + 320] = &irgb_add($px[$p + 320], &irgb_map($rvb, \@glb_map1)) if $glb_err1 && $y<199;
					$px[$p + 321] = &irgb_add($px[$p + 321], &irgb_map($rvb, \@glb_map2)) if $glb_err2 && $y<199 && ($x+$i)<319;
					$px[$p + 001] = &irgb_add($px[$p + 001], &irgb_map($rvb, \@glb_map3)) if $glb_err3 &&           ($x+$i)<319;
				}
				# pour voir les limites octets
				$px[$p] = $i&1? $forme : $fond if 0;
				$px[$p] ^= 0x0ff3fcff if $i==0 && 0;
			}
		}
		$| = 1; print "\r"; $| = 0;
	}
	%dist_cache = ();
    
	# ecriture des pixels et lecture
	#$out =~ s/.gif$/.c16.gif/;
	&write_image($out, @px);
    
	$out =~ s/.gif$//;
	&write_map("$out.mpa", 1, @px);
	&write_map("$out.mpb", 2, @px);
}
unlink($stopme);

if(0) {
	%m = ();
	foreach $out (<rgb/*.MAP>) {
		open(IN, "cygpath -w -s \"$out\" |"); $zz = <IN>; chomp($zz); close(IN);
		$zz=~y/~\\/_\//;
		$m{$out} = $zz;
	}
	foreach $out (keys %m) {
		rename($out, $m{$out});
	}
}

sub print_pal {
	my(@pal) = @_;
	my($i, @t);
	foreach $i (@pal) {
		my($r) = ($i>>20) & 255; 
		my($g) = ($i>>10) & 255;
		my($b) = ($i>>00) & 255;
		
		push(@t, sprintf("%3d,%3d,%3d", $r, $g, $b));
	}
	for $i (sort(@t)) {
		print "$i\n";
	}
}
# retourne la palette TO7/70
sub to770_palette {
    return (
        &rgb2irgb(0.0000,0.0000,0.0000), &rgb2irgb(1.0000,0.0000,0.0000), 
        &rgb2irgb(0.0000,1.0000,0.0000), &rgb2irgb(1.0000,1.0000,0.0000),
        &rgb2irgb(0.0000,0.0000,1.0000), &rgb2irgb(1.0000,0.0000,1.0000), 
        &rgb2irgb(0.0000,1.0000,1.0000), &rgb2irgb(1.0000,1.0000,1.0000),
        &rgb2irgb(0.4375,0.4375,0.4375), &rgb2irgb(0.6250,0.1875,0.1875), 
        &rgb2irgb(0.1875,0.6250,0.1875), &rgb2irgb(0.6250,0.6250,0.1875),
        &rgb2irgb(0.1875,0.1875,0.6250), &rgb2irgb(0.6250,0.1875,0.6250),
        &rgb2irgb(0.4375,0.8750,0.8750), &rgb2irgb(0.5375,0.6875,0.0000)
    ) if 0; # pas de gamma
    return (
        &rgb2irgb(0.0000,0.0000,0.0000), &rgb2irgb(1.0000,0.0000,0.0000), 
        &rgb2irgb(0.0000,1.0000,0.0000), &rgb2irgb(1.0000,1.0000,0.0000),
        &rgb2irgb(0.0000,0.0000,1.0000), &rgb2irgb(1.0000,0.0000,1.0000), 
        &rgb2irgb(0.0000,1.0000,1.0000), &rgb2irgb(1.0000,1.0000,1.0000),
        &rgb8irgb(212, 212, 212), &rgb8irgb(242, 152, 152), 
        &rgb8irgb(152, 242, 152), &rgb8irgb(242, 242, 152), 
        &rgb8irgb(152, 152, 242), &rgb8irgb(242, 152, 242), 
        &rgb8irgb(212, 255, 255), &rgb8irgb(255, 211,   1),  
    ) if 1; # gamma
    return (
        &rgb2irgb(0.0000,0.0000,0.0000), &rgb2irgb(1.0000,0.0000,0.0000), 
        &rgb2irgb(0.0000,1.0000,0.0000), &rgb2irgb(1.0000,1.0000,0.0000),
        &rgb2irgb(0.0000,0.0000,1.0000), &rgb2irgb(1.0000,0.0000,1.0000), 
        &rgb2irgb(0.0000,1.0000,1.0000), &rgb2irgb(1.0000,1.0000,1.0000),
        &rgb2irgb(0.6980,0.6980,0.6980), &rgb2irgb(0.8320,0.4640,0.4640), 
        &rgb2irgb(0.4640,0.8320,0.4640), &rgb2irgb(0.8320,0.8320,0.4640),
        &rgb2irgb(0.4640,0.4640,0.8320), &rgb2irgb(0.8320,0.4640,0.8320),
        &rgb2irgb(0.6980,0.9680,0.9680), &rgb2irgb(0.8710,0.4640,0.0000)
    ); # gamma
}

sub rgb8irgb {
    return &rgb2irgb($_[0]/255.0, $_[1]/255.0, $_[2]/255.0);
}

sub test_niveaux {
    my (@args) = @_;
    
    my($dither) = 0;
    
    # args=(seuil, niveaux..., -max, pixels...)
    my($seuil, $max, $t, @niv, @px, @pal) = 0;
    
    foreach $t (@args) {
        if($seuil==0) {
            $seuil = $t;
            $max = 0;
        } elsif($max==0) {
            if($t>=0) {
                push(@niv, $map_ef[$t]);
            } else {
                $max = -$t;
                for($t=0; $t<256; ++$t) {
                    my($m, $d, $n); $m = 1e30;
                    foreach $n (@niv) {$d = $n - $t; $d = -$d if $d<0; if($d<$m) {$m = $d; $pal[$t] = $n;}}
                }
            }
        } else {
            push(@px, $t) if 1;
            push(@px, ((($map_ef[$t>>20]<<10) + $map_ef[($t>>10) & 0xff])<<10) + $map_ef[$t & 0xff]) if 0;
        }
    }
    my($w, $h) = (320, 200);
    ($w, $h) = (160, 200) if 160*200==1+$#px;
    ($w, $h) = (160, 100) if 160*100==1+$#px;
    ($w, $h) = (80, 100)  if 80*100==1+$#px;
    ($w, $h) = (80, 50)   if 80*50==1+$#px;
    $seuil = $seuil*$seuil*$w*$h;
    
    # color reduce
    @niv = ();
    my($x, $y, $p, $m, $d, @out);
    if($dither) {
        my @tmp = @px;
        for($y=0, $p=0; $y<$h; ++$y) {
            for($x=0; $x<$w; ++$x, ++$p) {
                $rvb = $px[$p];
                my ($r,$v,$b) = ($pal[$rvb>>20], $pal[($rvb>>10) & 0xff], $pal[$rvb & 0xff]);
                push(@niv, $r, $v, $b);
                $px[$p] = ($r<<20) + ($v<<10) + $b;
                $rvb = &fs_diff($rvb, $px[$p]);
                $px[$p + $w - 1] = &fs_prop($px[$p + $w - 1], $rvb, \@glb_map0) if $glb_err0 && $y<$h-1 && $x>0;
                $px[$p + $w + 0] = &fs_prop($px[$p + $w + 0], $rvb, \@glb_map1) if $glb_err1 && $y<$h-1;
                $px[$p + $w + 1] = &fs_prop($px[$p + $w + 1], $rvb, \@glb_map2) if $glb_err2 && $y<$h-1 && $x<$w-1;
                $px[$p + 000001] = &fs_prop($px[$p + 000001], $rvb, \@glb_map3) if $glb_err3 &&            $x<$w-1;
            }
        }
        @px = @tmp;
    } else {
        foreach $t (@px) {push(@niv, $pal[$t>>20], $pal[($t>>10) & 0xff], $pal[$t & 0xff]);}
    }
    open(OUT,">.toto2.pnm"); print OUT "P6\n$w $h\n255\n", pack('C*', @niv), "\n"; close(OUT);
    @$glb_magick = ();
    $glb_magick->Set(page=>"$wx$h+0+0");
    $glb_magick->Read(".toto2.pnm");
    $glb_magick->Write(".toto3.png");
    unlink(".toto2.pnm");
    
    $glb_magick->Quantize(colors=>$max, colorspace=>"RGB", treedepth=>0, dither=>"False");
	$glb_magick->Write(".toto4.png");
    @niv = $glb_magick->GetPixels(map=>"RGB", height=>$h, normalize=>"True");
    my(%pal, $rvb);
    for($t=$#niv+1; ($t-=3)>=0;) {
        $rvb = &rgb2irgb(@niv[$t..$t+2]);
        $rvb = ((($pal[$rvb>>20]<<10) + $pal[($rvb>>10) & 0xff])<<10) + $pal[$rvb & 0xff];
        $pal{$rvb} = 1;
    }
    @niv = (keys(%pal), (0) x $max)[0..($max-1)];
	
    # dither & calcul d'erreur
    my($err) = 0;
    my($cache, %cache) = 1;
    for($y=$p=0; $err < $seuil && $y<$h; ++$y) {
        for($x=0; $err < $seuil && $x<$w; ++$x, ++$p) {
            $rvb = $px[$p];
            # on trouve le niv le plus proche
            $t = $cache{$rvb} if $cache;
            if(!$cache || !defined($t)) {
                $m = 1e30; foreach $t (@niv) {$d = &irgb_dist($t, $rvb); if($d<$m) {$m = $d;$px[$p] = $t;}}
                $cache{$rvb} = $px[$p] if $cache;
            } else {
                $m = &irgb_dist($t, $rvb);
                $px[$p] = $t;
            }
            push(@out, $px[$p]>>20, ($px[$p]>>10)&255, $px[$p]&255);
            $err += &sq($m); 
            if($dither) {
                $rvb = &fs_diff($rvb, $px[$p]);
                $px[$p + $w - 1] = &fs_prop($px[$p + $w - 1], $rvb, \@glb_map0) if $glb_err0 && $y<$h-1 && $x>0;
                $px[$p + $w + 0] = &fs_prop($px[$p + $w + 0], $rvb, \@glb_map1) if $glb_err1 && $y<$h-1;
                $px[$p + $w + 1] = &fs_prop($px[$p + $w + 1], $rvb, \@glb_map2) if $glb_err2 && $y<$h-1 && $x<$w-1;
                $px[$p + 000001] = &fs_prop($px[$p + 000001], $rvb, \@glb_map3) if $glb_err3 &&            $x<$w-1;
            }
        }
    }
    
    if($err < $seuil) {
        open(OUT,">.toto2.pnm"); print OUT "P6\n$w $h\n255\n", pack('C*', @out), "\n"; close(OUT);
        @$glb_magick = ();
        $glb_magick->Set(page=>"$wx$h+0+0");
        $glb_magick->Read(".toto2.pnm");
        $glb_magick->Write(".toto2.png");
        unlink(".toto2.pnm");
    }
    
    # fini
    $glb_magick->Set(page=>"320x200+0+0");
    sleep(0.5);
    return (sprintf("%.05f", sqrt($err/$w/$h)), @niv);
}

# calcul d'une palette de 16 couleurs
sub find_palette_orig {
    my($max, @px) = @_;

    # cas TO7
    return &to770_palette if $glb_to7pal;
    
    # vrai algo
    my($mask) = 0x0f03c0f0; $mask = -1;
    
    # si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
    # directement
    my($i, %pal);
    foreach $i (@px) {
        $pal{$i & $mask} = 1;
        last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	return @t if $#t<$max;
    %pal = ();
    
    # sinon on quantifie l'image:
    
    #return &xxx_palette($max, @px) if $#map_ef>=0;
    
    # on remap l'image aux niveau produits par les puces thomson!
    if($#map_ef>=0) {
        @t = ();
        my($x, $y, $p, $rvb, $r, $v, $b);
        for($y=0, $p=0; $y<200; ++$y) {
            for($x=0; $x<320; ++$x, ++$p) {
                $rvb = $px[$p];
		$r=$map_ef[$rvb>>20]; $v=$map_ef[($rvb>>10) & 0xff]; $b=$map_ef[$rvb & 0xff];
                push(@t, &ammag($r), &ammag($v), &ammag($b));
                #push(@t, $r=($rvb>>20), $v=(($rvb>>10) & 0xff), $b=($rvb & 0xff));
                if(1) {
                    $px[$p] = ((($r<<10)+$v)<<10)+$b;
                    $rvb = &irgb_sub($rvb, $px[$p]);
                    $px[$p + 319] = &irgb_uadd($px[$p + 319], &irgb_map($rvb, \@glb_map0)) if $glb_err0 && $y<199 && $x>0;
                    $px[$p + 320] = &irgb_uadd($px[$p + 320], &irgb_map($rvb, \@glb_map1)) if $glb_err1 && $y<199;
                    $px[$p + 321] = &irgb_uadd($px[$p + 321], &irgb_map($rvb, \@glb_map2)) if $glb_err2 && $y<199 && $x<319;
                    $px[$p + 001] = &irgb_uadd($px[$p + 001], &irgb_map($rvb, \@glb_map3)) if $glb_err3 &&           $x<319;
                }
            }
        }
        open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
        @$glb_magick = ();
        $glb_magick->Read(".toto2.pnm");
        #$glb_magick->Resize(geometry=>"160x100!");
        #$glb_magick->Resize(geometry=>"320x200!");
        $glb_magick->Write(".toto2.png");
        #$glb_magick->Read(".toto2.png");
        unlink(".toto2.pnm");
    }

	if(0) { #recherche
        # sinon on quantifie l'image:
    my($c, $err, @pal, $e, @p) = (0, 1e30);
    
    # on divise le nombre de pixels par 4
    if(1) {
        my($x, $y, $p, @t);
        for($p=$y=0; $y<200; $y+=2, $p+=320) {
            for($x=0; $x<320; $x+=2, $p+=2) {
                push(@t, &irgb_avg(&irgb_avg($px[$p], $px[$p+1]), &irgb_avg($px[$p+320], $px[$p+321])));
            }
        }
        @px = @t; @t = ();
        if(0) {
            for($p=$y=0; $y<100; $y+=1, $p+=0) {
                for($x=0; $x<160; $x+=2, $p+=2) {
                    push(@t, &irgb_avg($px[$p], $px[$p+1]));
                }
            }
            @px = @t; @t = ();
            if(0) {
                for($p=$y=0; $y<100; $y+=2, $p+=80) {
                    for($x=0; $x<80; $x+=1, $p+=1) {
                        push(@t, &irgb_avg($px[$p], $px[$p+80]));
                    }
                }
                @px = @t; @t = ();
            }
        }
    }
    
    # 0
    ($e, @p) = &test_niveaux($err, @ef_vals, -$max, @px);
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 1
    #($e, @p) = &test_niveaux($err, (0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 255), -$max, @px);
    ($e, @p) = &test_niveaux($err, (0, 50, 100, 150, 200, 250), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 2
    ($e, @p) = &test_niveaux($err, (0, 32, 64, 96, 128, 160, 192, 224, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 3
    ($e, @p) = &test_niveaux($err, (0, 50, 100, 200, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";
    
    # 4
    ($e, @p) = &test_niveaux($err, (0, 100, 140, 180, 200, 220, 240, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 5
    ($e, @p) = &test_niveaux($err, (0, 32, 64, 128, 192, 224, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 6
    ($e, @p) = &test_niveaux($err, (0, 16, 32, 48, 80, 112, 144, 208, 208, 240, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 7
    ($e, @p) = &test_niveaux($err, (0, 16, 32, 64, 128, 192, 224, 240, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";
    
    # 8
    ($e, @p) = &test_niveaux($err, (0, 64, 128, 192, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 9
    ($e, @p) = &test_niveaux($err, (0, 48, 96, 144, 192, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";
    
    # 10
    ($e, @p) = &test_niveaux($err, (0, 96, 112, 128, 144, 192, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 11
    ($e, @p) = &test_niveaux($err, (0, 128, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";

    # 12
    ($e, @p) = &test_niveaux($err, (0, 39, 101, 195, 255), -$max, @px); 
    print $c++,"=$e"; if($e < $err) {@pal = @p; $err = $e; print "*";} print "\n";
    
    return @pal;
	}

    
    
    my($colorspace) = "CMYK";  
    #$colorspace="HSV"; 
    $colorspace = "RGB"; 
    #$colorspace="YUV";
    $glb_magick->AdaptiveResize(geometry=>"80x200!") if 0;
    $glb_magick->Posterize(levels=>16, dither=>"False") if 0;
    $glb_magick->Posterize(levels=>6, dither=>"False") if 0;
    $glb_magick->Posterize(levels=>4, dither=>"False") if 0;
    $glb_magick->Posterize(levels=>3, dither=>"False") if 0;
    # pas mal du tout: 
    $glb_magick->Quantize(colors=>$max, colorspace=>$colorspace, treedepth=>0, dither=>"False");
	@t = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	for($i=$#t+1; ($i-=3)>=0;) {
        $rvb = &rgb2irgb(@t[$i..$i+2]);
        #$rvb = ((($map_ef2[$rvb>>20]<<10) + $map_ef2[($rvb>>10) & 0xff])<<10) + $map_ef2[$rvb & 0xff] if $#map_ef>=0;
        $rvb = ((($map_ef[$rvb>>20]<<10) + $map_ef[($rvb>>10) & 0xff])<<10) + $map_ef[$rvb & 0xff] if $#map_ef>=0;
        $pal{$rvb & $mask} = 1;
    }
    @t = (keys(%pal), (0) x $max)[0..($max-1)];
    #foreach $t (@t) {	print &irgb2hex($t), "\n"; }
	return @t;
}

# calcul d'une palette de 16 couleurs
sub find_palette {
	my($max, @px) = @_;

	# cas TO7
	return &to770_palette if $glb_to7pal;
    
	# vrai algo
	my($mask) = 0x0f03c0f0; $mask = -1;
    
	# si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
	# directement
	my($i, %pal);
	foreach $i (@px) {
		$pal{$i & $mask} = 1;
		last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	#for $t (@t) {
	#		print &irgb2hex($t), "  = ", $pal{$t},"\n";
	#}
	return @t if $#t<$max;
	%pal = ();
    
	# sinon on quantifie l'image:
	my($use_dith) = 1;
	my($alt) = 0;
    
	#return &xxx_palette($max, @px) if $#map_ef>=0;
    
	# on remap l'image aux niveau produits par les puces thomson!
	if($#map_ef>=0) {
		@t = simple_dither($use_dith, @px) unless $alt;
		@t = prox_dither  ($use_dith, @px) if $alt;
	}
	
	# idee par groupe de $w pixels on sature les valeurs RGB avec
	# les min/max ontenus pour ce groupe. L'idee est de réduire
	# la disperssion des couleurs
	if(1) {
		my($w) = 8;
		for($i=0; $i<=$#t; $i+=3*$w) {
			my($r,$v,$b) = (1,1,1);
			my($R,$V,$B) = (0,0,0);
			my($j);
			for($j=$i; $j<$i+$w*3; $j+=3) {
				$r = $t[$j+0] if $t[$j+0]<$r;
				$v = $t[$j+1] if $t[$j+1]<$v;
				$b = $t[$j+2] if $t[$j+2]<$b;
				$R = $t[$j+0] if $t[$j+0]>$R;
				$V = $t[$j+1] if $t[$j+1]>$V;
				$B = $t[$j+2] if $t[$j+2]>$B;
			}
			my($t) = 0.5;
			for($j=$i; $j<$i+$w*3; $j+=3) {
				$t[$j+0] = $t[$j+0] < (1-$t)*$r + $t*$R ? $r : $R;
				$t[$j+1] = $t[$j+1] < (1-$t)*$v + $t*$V ? $v : $V;
				$t[$j+2] = $t[$j+2] < (1-$t)*$b + $t*$B ? $b : $B;
			}
		}
	}
    
	# on réduit à 64 couls
	$glb_magick->Quantize(colors=>($alt?48:24)*0+64*1+128*0+256*0, colorspace=>"RGB", treedepth=>0, dither=>($use_dith && !$alt & 0?"True":"False"));
	$glb_magick->Write("toto3.gif");
	@t = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	
	# on comptabilise les couleurs renormalisées au format Thomson
	%pal = ();
	$pal{0} = 1+$#t;
	for($i=$#t+1; ($i-=3)>=0;) {
		$rvb = &rgb2irgb(@t[$i..$i+2]);
		#$rvb = ((($map_ef2[$rvb>>20]<<10) + $map_ef2[($rvb>>10) & 0xff])<<10) + $map_ef2[$rvb & 0xff] if $#map_ef>=0;
		$rvb = ((($map_ef[$rvb>>20]<<10) + $map_ef[($rvb>>10) & 0xff])<<10) + $map_ef[$rvb & 0xff] if $#map_ef>=0;
		++$pal{$rvb & $mask};
	}
	
	# on trie par frequence
	my(@cpt) = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	
	# selection par popularité?
	return 	(@cpt, (0) x $max)[0..($max-1)] if 0;
	
	# affichage des stats
	my($dbg) = 0;
	if($dbg) {
		for $t (@cpt) {
			print &irgb2hex($t), "  = ", $pal{$t},"\n";
		}
	}

	# on coupe les couls sous-représentées
	my($thr) = 8;
	@t = @cpt; @cpt = ();
	for $t (@t) {
		push(@cpt, $t) if $pal{$t} >= $thr;
	}
		
	# on prend la couleur la plus frequente, puis la plus loin de celle là jusqu'à 10 couls ensuite une fois sur 2 on prend la plus ancienne
	@t = ();
	push(@t, shift(@cpt));
	while($#t < $max && $#cpt>=0) {
		#print "\n\n";
		#for $t (@t) {
		#	print &irgb2hex($t), "  = ", $pal{$t},"\n";
		#}
		if($#t < 10 || ($#t & 1)) {
			#print "\n\n\n$#t, plus loin\n";
			$i = &find_furthest(\@t, \@cpt);
			push(@t, splice(@cpt, $i, 1, ()));
		} else {
			#print "\n\n\n$#t, plus freq";
			# on prends la plus frequente
			push(@t, shift(@cpt));
		}
	}
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	$dbg = 0;
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", $pal{$t}, " ", $r,",",$g,",",$b," ",$t,"\n"; 
		}
	}
	
	return @t;
}

# dithering simple sans contraintes de proximité
sub simple_dither {
	my($use_dith, @px) = @_;
	
	my($x, $y, $p, $rvb, $r, $v, $b, @t);
	for($y=0, $p=0; $y<200; ++$y) {
		for($x=0; $x<320; ++$x, ++$p) {
			$rvb = $px[$p];
			$r=$map_ef[$rvb>>20]; $v=$map_ef[($rvb>>10) & 0xff]; $b=$map_ef[$rvb & 0xff];
			push(@t, &ammag($r), &ammag($v), &ammag($b));
			#push(@t, $r=($rvb>>20), $v=(($rvb>>10) & 0xff), $b=($rvb & 0xff));
			if($use_dith) {
				$px[$p] = ((($r<<10)+$v)<<10)+$b;
				$rvb = &irgb_sub($rvb, $px[$p]);
				$px[$p + 319] = &irgb_uadd($px[$p + 319], &irgb_map($rvb, \@glb_map0)) if $glb_err0 && $y<199 && $x>0;
				$px[$p + 320] = &irgb_uadd($px[$p + 320], &irgb_map($rvb, \@glb_map1)) if $glb_err1 && $y<199;
				$px[$p + 321] = &irgb_uadd($px[$p + 321], &irgb_map($rvb, \@glb_map2)) if $glb_err2 && $y<199 && $x<319;
				$px[$p + 001] = &irgb_uadd($px[$p + 001], &irgb_map($rvb, \@glb_map3)) if $glb_err3 &&           $x<319;
			}
		}
	}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	
	$glb_magick->Write("toto2_.png");
	
	return @t;
}

# dither sans contraintes de couleurs, mais avec contrainte de proximité
sub prox_dither {
	my($use_dith, @px) = @_;
	
	my($x, $y, $fond, $forme, $i, $p, $rvb, $r, $v, $b, @t);
	for($y=$p=0; $y<200; ++$y) {
		for($x=0; $x<320; $x += 8) {
			($fond, $forme) = &prox_couple(@px[$p..$p+7]);
			for($i = 0; $i<8; ++$i, ++$p) {
				$rvb = $px[$p];
				$rvb = &irgb_dist($fond, $rvb) < &irgb_dist($forme, $rvb) ? $fond : $forme;
				$r=$map_ef[$rvb>>20]; $v=$map_ef[($rvb>>10) & 0xff]; $b=$map_ef[$rvb & 0xff];
				push(@t, &ammag($r), &ammag($v), &ammag($b));
				if($use_dither | 1) {
					#$px[$p] = ((($r<<10)+$v)<<10)+$b;
					$rvb = &irgb_sub($px[$p], $rvb);
					$px[$p + 319] = &irgb_uadd($px[$p + 319], &irgb_map($rvb, \@glb_map0)) if $glb_err0 && $y<199 && $x+$i>0;
					$px[$p + 320] = &irgb_uadd($px[$p + 320], &irgb_map($rvb, \@glb_map1)) if $glb_err1 && $y<199;
					$px[$p + 321] = &irgb_uadd($px[$p + 321], &irgb_map($rvb, \@glb_map2)) if $glb_err2 && $y<199 && $x+$i<319;
					$px[$p + 001] = &irgb_uadd($px[$p + 001], &irgb_map($rvb, \@glb_map3)) if $glb_err3 &&           $x+$i<319;
				}
			}
		}
	}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	#$glb_magick->Write(".toto2.png");
	unlink(".toto2.pnm");
	
	return @t;
}

sub prox_couple {
	my(@octet) = @_;
	
	my($i, $im, $j, $jm, $d, $dm, $rgb, $r, $g, $b, %cpt, @px);
	    
	# dither de l'octet sans contraintes pour extraire les stats
	@px = (@octet);
	for($i=0; $i<8; ++$i) {
		$rgb = $px[$i];
		$r=$map_ef[$rgb>>20]; $v=$map_ef[($rgb>>10) & 0xff]; $b=$map_ef[$rgb & 0xff];
		++$cpt{$px[$i] = ((($r<<10)+$v)<<10)+$b};
		$px[$i+1] = &irgb_add($px[$i+1], &irgb_map(&irgb_sub($rgb, $px[$i]), \@glb_map3)) if $i<7;
	}
    
	# on trie par frequence
	my(@cpt) = (sort { $cpt{$b} - $cpt{$a} } keys %cpt);
    
	#print "\n\n";
	#foreach $t (@octet) {
	#	print &irgb2hex($t), " ";
	#}
	#print "\n\n";
	#foreach $t (@cpt) {
	#	print &irgb2hex($t), " = ", $cpt{$t}, "\n";
	#}
  
	# 1 ou 2 couls utilisées: pas de probs
	if($#cpt<=1) {
		# on s'assure qu'on en a au moins 2
		$cpt[1] = $cpt[0] if $#cpt==0;

		return ($cpt[1], $cpt[0]);
	}
    
	# les 2 couls principales couvrent 7 pixels sur les 8, on les gardes, tant pis pour la mintorité
	if($cpt{$cpt[0]} + $cpt{$cpt[1]} >= 6) {
		return ($cpt[1], $cpt[0]);        
	}
	
	# si la 1ere couvre 4 pixels, on prend comme 2eme celle qui fait le moins d'err
	if($cpt{$cpt[0]} >= 6) {
		$dm = 1e30;
		for($i=1; $i<=$#cpt; ++$i) {
			@px = (@octet);
			for($d = $j = 0; $j<8 && $d<$dm; ++$j) {
				$d1 = &irgb_dist($cpt[0], $px[$j]);
				$d2 = &irgb_dist($cpt[$i],$px[$j]);
				if($d1 < $d2) {$d += &sq($d1); $rgb = $cpt[0];} else {$d += &sq($d2); $rgb = $cpt[$i];}
				$px[$j+1] = &irgb_add($px[$j+1], &irgb_map(&irgb_sub($px[$j], $rgb), \@glb_map3)) if $glb_err3 && $j<7;
			}
			if($d < $dm) {$dm = $d; $im = $i;}
		}
		return ($cpt[$im], $cpt[0]);
	}

	# sinon tester tous les couple avec dither
	my($r, $rm);
	$dm = 1e30;
	for($i=0; $i<=$#cpt; ++$i) {
		for($j=0; $j<$i; ++$j) {
			@px = (@octet);
			for($r = $d = $k = 0; $k<8 && $d<$dm; ++$k) {
				$di = &irgb_dist($cpt[$i], $px[$k]);
				$dj = &irgb_dist($cpt[$j], $px[$k]);
				if($di <= $dj) {$r |= 1; $rgb = $cpt[$i]; $d += &sq($di);} else {$r |= 2; $rgb = $cpt[$j]; $d += &sq($dj);}
				$px[$k+1] = &irgb_add($px[$k+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $k<7;
			}
			if($d < $dm) {$rm = $r; $dm = $d; $im = $i; $jm = $j}
		}
	}
	return ($cpt[$im], $cpt[$jm]);
}

sub find_furthest {
	my ($set, $cols) = @_;
	my ($d, $dm, $i, $im);
	for($i = $#{$cols}, $dm = $im = 0; $i>=0; --$i) {
		$d = &set_dist($cols->[$i], $set);
		#print "$i ", &irgb2hex($cols->[$i])," ==> $d, $dm\n";
		if($d > $dm) {$dm = $d; $im = $i; #print"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";
		}
	}
	#print "*** ", &irgb2hex($cols->[$im])," $im ($dm)\n";
	return $im;
}

sub set_dist {
	my($rgb, $set) = @_;
	my($dm, $d, $col) = 1e30;
	my $dc = 0;
	foreach $col (@$set) {
		$d = &irgb_dist($rgb, $col);
		$dc += $d;
		#print &irgb2hex($rgb),",",&irgb2hex($col), "====$d\n";
		if($d<$dm) {$dm = $d;}
	}
	return $dm; # + $dc;
}

# sauvegarde de l'image
sub write_image {
	my($file, @px) = @_;
    
	# on replace tout entre 0 et 255
    my($t, $c, @p);
    foreach $t (@px) {
        my($b) = $t & 0x100 ? 0 : $t & 0xff; $t >>= 10;
        my($v) = $t & 0x100 ? 0 : $t & 0xff; $t >>= 10;
        my($r) = $t & 0x100 ? 0 : $t & 0xff;
        if(0        && $#map_ef>=0) {
            $r = $map_ef2[$r];
            $v = $map_ef2[$v];
            $b = $map_ef2[$b];
        }
	push(@p, &ammag($r), &ammag($v), &ammag($b)); #, $r, $v, $b);
    }
    # on passe par un fichier temporaire
    open(OUT,">.toto.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @p), "\n"; close(OUT);
    #open(OUT, ">.toto.pnm"); print OUT "P6\n640 400\n255\n"; for($t = 0; $t<=$#p; $t+=640*3) {print OUT pack('C*', @p[$t..$t+640*3-1], @p[$t..$t+640*3-1]);} print OUT "\n"; close(OUT);
    @$glb_magick = ();
    $glb_magick->Read(".toto.pnm");
    $glb_magick->Set(page=>"320x200+0+0");
#    $glb_magick->Set(page=>"640x400+0+0");
    #$glb_magick->Gamma(gamma=>1.2);
    #$glb_magick->Resize(geometry=>"640x400!");
	#$glb_magick->Border(width=>"320",height=>"100",color=>"black");    
	#unlink(".toto.pnm");

	# sauvegarde
	$glb_magick->Write($file);
}

# gamma / normalize / sigmoidal
# 0 = orig / Linear / off
# 1 = orig / Linear / on
# 2 = orig / Normalize / off
# 3 = orig / Normalize / on
# 4 = gamma / Linear / off
# 5 = gamma / Linear / on
# 6 = gamma / Normalize / off
# 7 = gamma / Normalize / on

# lit une image au format 320 x 200 sous la forme r10v10b10
sub read_image {
	my($file) = @_;

	@$glb_magick = ();		
	my($x) = $glb_magick->Read($file);
	warn "$x" if "$x";

	# formattage en 320x200 si necessaire
	$glb_magick->Enhance();
	$glb_magick->Normalize(); #
	#$glb_magick->LinearStretch('black-point'=>0, 'white-point'=>1);
	#$glb_magick->Contrast(sharpen=>"True");
	#$glb_magick->Set(antialias=>"True");
	$glb_magick->SigmoidalContrast(contrast=>2);
	$glb_magick->AdaptiveResize(geometry=>"320x200", filter=>"lanczos", blur=>1);
	$glb_magick->Border(width=>"320",height=>"100",color=>"black");
	#  $glb_magick->Blur(1);
	#  $glb_magick->OilPaint(2);
	$glb_magick->Set(gravity=>"Center");
	#	$glb_magick->Crop(geometry=>"320x200!", gravity=>"center");
	$glb_magick->Crop(geometry=>"320x200!");
	$glb_magick->Set(page=>"320x200+0+0");
	$glb_magick->Resize(geometry=>"320x200!", filter=>"lanczos", blur=>1);
	#$glb_magick->ReduceNoise(radius=>0);
	#$glb_magick->Gamma(gamma=>0.8) if $glb_to7pal;
	#$glb_magick->Gamma(gamma=>0.45);
	#$glb_magick->AdaptiveSharpen(radius=>3);
	#$glb_magick->AdaptiveBlur(radius=>4);
	#$glb_magick->Contrast(sharpen=>"True");
	#$glb_magick->Evaluate(operator=>"Multiply", value=>"0.9");

	#$glb_magick->Quantize(colors=>$glb_maxcol, colorspace=>"CYMK", dither=>"True");
	#$glb_magick->OrderedDither(threshold=>"h4x4", channel=>"RGB");
	if($glb_dith>=2) {
		#dither en 16 couls
		my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
		my($i, $j, $t, $p, @p);
		my($m) = $glb_dith-1;
		for($j=$p=0; $j<200; ++$j) {
			for($i=0; $i<320; ++$i) {
				$t = $t[$p] * $m; ++$t if $t<$m && $t - int($t)>=$mat[$i % $mat_x][$j % $mat_y]; $t[$p++] = (int($t)*255)/$m;
				$t = $t[$p] * $m; ++$t if $t<$m && $t - int($t)>=$mat[$i % $mat_x][$j % $mat_y]; $t[$p++] = (int($t)*255)/$m;
				$t = $t[$p] * $m; ++$t if $t<$m && $t - int($t)>=$mat[$i % $mat_x][$j % $mat_y]; $t[$p++] = (int($t)*255)/$m;
			}
		}    
		open(OUT,">.toto.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
		@$glb_magick = ();
		$glb_magick->Read(".toto.pnm");
		$glb_magick->Write(".toto.png");
		unlink(".toto.pnm");
	}
	my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	my($i, @px);
	for($i = 0; $i<$#t; $i += 3) {
		push(@px, &rgb2irgb($t[$i], $t[$i+1], $t[$i+2]));
	}
	
	#$glb_magick->Write("totof.png");
	
	return @px;
}

sub ammag {
	return $_[0] unless $glb_gamma;
	my $t = $_[0]/255;
	#if($t<=0.018) {$t = 4.5*$t;} else {$t = 1.099*($t**(1/$glb_gamma))-0.099;}
	$t = $t**(1/$glb_gamma);
	return xint(255*$t);
}

sub gamma {
	return $_[0] unless $glb_gamma;
	my $t = $_[0]/255;
	#if($t<=0.081) {$t = $t/4.5;} else {$t = (($t+0.099)/1.099)**$glb_gamma;}
	$t = $t**$glb_gamma;
	return xint($t*255); #**1.2; #**1.4;
}

# affichage
sub irgb2hex {
	my($irgb) = @_;
	my($s) = "";
	if($irgb & 0x100) {$s = sprintf("-%02x$s", (($irgb ^ 0x1ff)&0xff) + 1);} else {$s = sprintf("+%02x$s", $irgb & 0xff);} $irgb >>= 10;
	if($irgb & 0x100) {$s = sprintf("-%02x$s", (($irgb ^ 0x1ff)&0xff) + 1);} else {$s = sprintf("+%02x$s", $irgb & 0xff);} $irgb >>= 10;
	if($irgb & 0x100) {$s = sprintf("-%02x$s", (($irgb ^ 0x1ff)&0xff) + 1);} else {$s = sprintf("+%02x$s", $irgb & 0xff);} $irgb >>= 10;
	return $s;
}

# addition d'une valeur irgb signée .. inclu saturation -256 +255
sub irgb_add {
	my($irgb1, $irgb2) = @_;
    
	my($r) = $irgb1 + $irgb2;
	my($o) = (($irgb1 & 0x0ff3fcff) + ($irgb2 & 0x0ff3fcff)) ^ ($r>>1);
	$r = ($r & ~0x000003ff) | (0x00000100 - (($r & 0x00000100)>>8)) if $o & 0x00000100;
	$r = ($r & ~0x000ffc00) | (0x00040000 - (($r & 0x00040000)>>8)) if $o & 0x00040000;
	$r = ($r & ~0x3ff00000) | (0x10000000 - (($r & 0x10000000)>>8)) if $o & 0x10000000;
	return $r & 0x1ff7fdff if 1; # saturation -256 et +255
}   

# addition d'une valeur irgb signée .. inclu saturation 0 +255
sub irgb_uadd {
	return &irgb_sat(&irgb_add(@_));
}

# sature les irgb<0 à 0
sub irgb_sat {
	my($irgb) = @_;
    
	return (((0x10040100 - (($irgb & 0x10040100)>>8)) ^ 0xff3fcff) & $irgb) & 0xff3fcff;
}   

# soustraction de deux valeurs irgb>=0 (pas de satur)
sub irgb_sub {
	my($rgb1, $rgb2) = @_;
	return (($rgb1 | 0x20080200) - $rgb2) & 0x1ff7fdff;
}

# valeur opposée
sub irgb_neg {
	my($rgb) = @_;
	return (0x20080200 - $rgb) & 0x1ff7fdff;
}

# module du vecteur irgb
sub irgb_module {
	my($rgb) = @_;
	my($d);
	$d  = $glb_sqr[0x1ff & $rgb]; $rgb >>= 10;
	$d += $glb_sqr[0x1ff & $rgb]; $rgb >>= 10;
	$d += $glb_sqr[0x1ff & $rgb];
	return sqrt($d);
}

# applique une table sur un irgb (en gros ca sert pour les multiplications par des constantes)
sub irgb_map {
	my($rgb, $map) = @_;
	my($r);
	$r  = $map->[$rgb & 0x1ff];     $rgb >>= 10;
	$r |= $map->[$rgb & 0x1ff]<<10; $rgb >>= 10;
	$r |= $map->[$rgb]<<20;
	return $r;
}

# rgb (0..1) vers irgb
sub rgb2irgb {
	my(@rgb) = @_;
	my($t);
	if($glb_gamma) {
		$rgb[0] = &gamma($rgb[0]*255)/255;
		$rgb[1] = &gamma($rgb[1]*255)/255;
		$rgb[2] = &gamma($rgb[2]*255)/255;
	}
	$t = (int(255*$rgb[0]) & 0x1ff); 
	$t = (int(255*$rgb[1]) & 0x1ff) | ($t<<10);
	$t = (int(255*$rgb[2]) & 0x1ff) | ($t<<10);
	return $t;
}

# irgb vers rgb (0..1). si la composante est negative, elle est clampée à 0
sub irgb2rgb {
	my($t) = @_;
    
	my($b) = ($t & 0x100) ? 0 : ($t & 255)/255.0; $t >>= 10;
	my($v) = ($t & 0x100) ? 0 : ($t & 255)/255.0; $t >>= 10;
	my($r) = ($t & 0x100) ? 0 : ($t & 255)/255.0; 
    
	return ($r, $v, $b);
}

# moyenne de 2 couleurs >= 0
sub irgb_avg {
	my($rgb1, $rgb2) = @_;
	return (($rgb1 + $rgb2 + 0x100401) & ~0x20180601)>>1;
}

# rgb (0..1) vers xyz
sub rgb2xyz {
	my($r, $v, $b) =  @_;
	return (0.618*$r + 0.177*$v + 0.205*$b, 
		0.299*$r + 0.587*$v + 0.114*$b, 
                           0.056*$v + 0.944*$b);
}

# xyz vers cie lab
sub xyz2lab {
	my($x, $y, $z) = @_;
	#my($xn, $yn, $zn) = &rgb2xyz(1,1,1); $x /= $xn; $y /= $yn; $z /= $zn;
	my($l,$a,$b);
	if($y>0.008856) {
		$l = 116*($y ** 0.33333333333333) - 16;
	} else {
		$l = 903*$y;
	}
	$a = 500*(&f_lab($x) - &f_lab($y));
	$b = 200*(&f_lab($y) - &f_lab($z));
	return ($l,$a,$b);
}

sub f_lab {
	my($v) = @_;
    
	if($v>0.008856) {
		return $v ** 0.333333333333333;
	} else {
		return 7.787*$v + 16/116.0;
	}
}

# rgb vers lab
sub rgb2lab {
	return &xyz2lab(&rgb2xyz(@_));
}

# approximated CIE formula from http://www.compuphase.com/cmetric.htm#GAMMA
sub irgb_cie_dist_fast {
	my($rgb1, $rgb2) = @_;
        
	my($rmean) = (($rgb1 + $rgb2) >> 21) & 0x1ff;
	my($rgb) = &irgb_sub($rgb1, $rgb2);
    
	$d  = ($glb_sqr[0x1ff & $rgb] * (512 + $rmean)) >> 8; $rgb >>= 10;
	$d +=  $glb_sqr[0x1ff & $rgb] * 4; $rgb >>= 10;
	$d += ($glb_sqr[0x1ff & $rgb] * (767 - $rmean)) >> 8;
	return sqrt($d);
}

# calcule la distance entre les deux couleurs r10g10b10
sub irgb_dist {
	my($rgb1, $rgb2) = @_;
	#die &irgb2hex($rgb1) if $rgb1 & 0x10040100;
	#die &irgb2hex($rgb2) if $rgb2 & 0x10040100;
	if($glb_lab) {
		return &irgb_cie_dist_fast($rgb1, $rgb2);
		#my($k) = $rgb1."_".$rgb2;
		my($d); # = $dist_cache{$k};
		#if(!defined $d) {
		my($r1, $g1, $b1) = &xyz2lab(&rgb2xyz(&irgb2rgb($rgb1)));
		my($r2, $g2, $b2) = &xyz2lab(&rgb2xyz(&irgb2rgb($rgb2)));
        
		$r1 -= $r2; $g1 -= $g2; $b1 -= $b2;
		$d = sqrt($r1*$r1 + $g1*$g1 + $b1*$b1);
		#$dist_cache{$k} = $d;
		#}
		return $d;
	} else {
		return &irgb_module(&irgb_sub($rgb1, $rgb2));
	}
}

# retourne le couple forme/fond pour un octet donné
sub couple {
    my(@octet) = @_;
    
    return &couple2(@octet) if 0;
    return &couple3(@octet) if 0;
    return &couple4(@octet) if 1;
    
    # on commence un dither classique mais horizontal de l'octet
    my($i, $im, $j, $jm, $d, $dm, $rgb, @octet_pal);
    $#octet_pal = 7;
    for($i=0; $i<8; ++$i) {
        $rgb = $octet[$i];
        # on trouve la coul la plus proche
        $dm = 1e30;
        for($j=0; $j<$glb_maxcol; ++$j) {
            $d = &irgb_dist($glb_pal[$j], $rgb);
            if($d<$dm) {$dm = $d; $octet_pal[$i] = $j;}
        }
        # on propage l'erreur
        #$qq = &irgb_map(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]]), \@glb_map3);
        #print &irgb2hex($octet[$i]),",",&irgb2hex($glb_pal[$octet_pal[$i]])," e=",&irgb2hex(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]])), " " if $qq;
        #print "m=",&irgb2hex($qq)," " if $qq;
        #print &irgb2hex($octet[$i + 1]), " => " if $qq;
        $octet[$i+1] = &irgb_add($octet[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$octet_pal[$i]]), \@glb_map3)) if $i<7;
        #print &irgb2hex($octet[$i + 1]), "\n" if $qq;
    }
    
    # ensuite on trouve le couple qui conduit au minimum d'erreur
    $dm = 1e30; my($t, @line);
    for($i=0; $i<$glb_maxcol; ++$i) {
        for($j=0; $j<$i; ++$j) {
            $d  = &couple_dist($i, $j, $octet_pal[0]);
            $d += &couple_dist($i, $j, $octet_pal[1])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[2])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[3])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[4])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[5])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[6])  if $d<$dm;
            $d += &couple_dist($i, $j, $octet_pal[7])  if $d<$dm;
            
 			if($d<$dm) {$dm = $d; $im = $i; $jm = $j;}
        }
    }
    
	return ($glb_pal[$im], $glb_pal[$jm]);
}

sub couple_dist {
    my($forme, $fond, $pixel) = @_;
    
    my($t, $a, $b) = $pixel*$glb_maxcol;
    return ($a=$glb_dist[$t + $forme]) < ($b=$glb_dist[$t + $fond]) ? $a : $b;
}

sub couple_dist_sq {
    my($t) = &couple_dist(@_);
    return $t*$t;
}

sub couple2 {
    my(@octet) = @_;
    my($d, $dm, $im, $jm); $dm = 1e30; 
    for($i=0; $i<$glb_maxcol; ++$i) {
        for($j=0; $j<$i; ++$j) {
            $d  = &couple2_dist($i, $j, $octet[0]);
            $d += &couple2_dist($i, $j, $octet[1])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[2])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[3])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[4])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[5])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[6])  if $d<$dm;
            $d += &couple2_dist($i, $j, $octet[7])  if $d<$dm;
            
 			if($d<$dm) {$dm = $d; $im = $i; $jm = $j;}
        }
    }
	return ($glb_pal[$im], $glb_pal[$jm]);    
}

sub couple2_dist {
    my($forme, $fond, $pixel) = @_;
    my($a,$b);
    return ($a=&irgb_dist($glb_pal[$forme], $pixel)) < ($b=&irgb_dist($glb_pal[$fond], $pixel)) ? $a : $b;
}

sub couple2_dist_sq {
    my($t) = &couple2_dist(@_);
    return $t * $t;
}

# retourne le couple forme/fond pour un octet donné
sub couple3 {
    my(@octet) = @_;
    
    # on commence un dither classique mais horizontal de l'octet
    my($i, $im, $j, $jm, $d, $dm, $rgb, @octet_pal);
    $#octet_pal = 7;
    for($i=0; $i<8; ++$i) {
        $rgb = $octet[$i];
        # on trouve la coul la plus proche
        $dm = 1e30;
        for($j=0; $j<$glb_maxcol; ++$j) {
            $d = &irgb_dist($glb_pal[$j], $rgb);
            if($d<$dm) {$dm = $d; $octet_pal[$i] = $j;}
        }
        # on propage l'erreur
        #$qq = &irgb_map(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]]), \@glb_map3);
        #print &irgb2hex($octet[$i]),",",&irgb2hex($glb_pal[$octet_pal[$i]])," e=",&irgb2hex(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]])), " " if $qq;
        #print "m=",&irgb2hex($qq)," " if $qq;
        #print &irgb2hex($octet[$i + 1]), " => " if $qq;
        $octet[$i+1] = &irgb_uadd($octet[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$octet_pal[$i]]), \@glb_map3)) if $i<7;
        #print &irgb2hex($octet[$i + 1]), "\n" if $qq;
    }
    
    #la couleur fond est la couleur la plus choisie par octet_pal[i]
    my(@cpt) = (0) x 8;
    $i = -1;
    foreach $j (@octet_pal) {if(++$cpt[$j] > $i) {$i = $cpt[$j]; $im = $j;}}
        
    # ensuite on trouve le couple qui conduit au minimum d'erreur
    $dm = 1e30; my($t, @line);
    for($j=0; $j<$glb_maxcol; ++$j) {
        $d  = &couple_dist($im, $j, $octet_pal[0]);
        $d += &couple_dist($im, $j, $octet_pal[1])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[2])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[3])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[4])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[5])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[6])  if $d<$dm;
        $d += &couple_dist($im, $j, $octet_pal[7])  if $d<$dm;
         
        if($d<$dm) {$dm = $d; $jm = $j;}
    }
    
	return ($glb_pal[$im], $glb_pal[$jm]);
}

sub couple4 {
    return &couple5(@_) if 0;

    my(@octet) = @_;
    
    # on commence un dither classique mais horizontal de l'octet
    my($i, $im, $j, $jm, $d, $dm, $rgb, @octet_pal);
    $#octet_pal = 7;
    for($i=0; $i<8; ++$i) {
        $rgb = $octet[$i];
        # on trouve la coul la plus proche
        $dm = 1e30;
        for($j=0; $j<$glb_maxcol; ++$j) {
            $d = &irgb_dist($glb_pal[$j], $rgb);
            if($d<$dm) {$dm = $d; $octet_pal[$i] = $j;}
        }
        # on propage l'erreur
        #$qq = &irgb_map(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]]), \@glb_map3);
        #print &irgb2hex($octet[$i]),",",&irgb2hex($glb_pal[$octet_pal[$i]])," e=",&irgb2hex(&irgb_sub($octet[$i], $glb_pal[$octet_pal[$i]])), " " if $qq;
        #print "m=",&irgb2hex($qq)," " if $qq;
        #print &irgb2hex($octet[$i + 1]), " => " if $qq;
        $octet[$i+1] = &irgb_uadd($octet[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$octet_pal[$i]]), \@glb_map3)) if $i<7;
        #print &irgb2hex($octet[$i + 1]), "\n" if $qq;
    }
    
    # comptage des occurences
    $dm = -1; my(@cpt) = (0) x $glb_maxcol; my($filt_cpt) = 0;
    foreach $j (@octet_pal) {if(++$cpt[$j] > $dm) {$dm = $cpt[$jm = $j];}}
    if($dm >= 8) {
        $im = 0;
    } elsif($dm >= 4) {
        # une couleur domine de loin: on la prend en fond. On cherche
        # alors la forme qui minimise l'erreur sur l'octet.
        $dm = 1e30; $im = 0;
        for($i = 0; $i < $glb_maxcol; ++$i) {
            next unless $cpt[$i]>0 || $filt_cpt;
            $d  = &couple_dist($i, $jm, $octet_pal[0]);
            $d += &couple_dist($i, $jm, $octet_pal[1])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[2])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[3])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[4])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[5])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[6])  if $d<$dm;
            $d += &couple_dist($i, $jm, $octet_pal[7])  if $d<$dm;
            
 			if($d<$dm) {$dm = $d; $im = $i;}
        }
    } else {
        # sinon on essaye tous les couples sans dither
        return &couple2(@_) if 0;
        # avec dither
        return &couple2(@octet) if 0;
        $dm = 1e30; $im = 0;
        for($i=0; $i<$glb_maxcol; ++$i) {
            next unless $cpt[$i]>0 || $filt_cpt || 1;
            for($j=0; $j<$i; ++$j) {
                next unless $cpt[$j]>0 || $filt_cpt;
                $d  = &couple_dist($i, $j, $octet_pal[0]);
                $d += &couple_dist($i, $j, $octet_pal[1])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[2])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[3])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[4])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[5])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[6])  if $d<$dm;
                $d += &couple_dist($i, $j, $octet_pal[7])  if $d<$dm;
            
                if($d<$dm) {$dm = $d; $im = $i; $jm = $j;}
            }
        }
    }
    
	return ($glb_pal[$im], $glb_pal[$jm]);
}

sub couple5__ {
    my(@octet) = @_;
    
    # calcul de la coul moyenne sur l'octet
    my(@moy);
    $moy[0] = (($octet[0] + $octet[1])>>1) & 0xff3fcff;
    $moy[1] = (($octet[2] + $octet[3])>>1) & 0xff3fcff;
    $moy[2] = (($octet[4] + $octet[5])>>1) & 0xff3fcff;
    $moy[3] = (($octet[6] + $octet[7])>>1) & 0xff3fcff;
    
    $moy[0] = (($moy[0] + $moy[1])>>1) & 0xff3fcff;
    $moy[1] = (($moy[2] + $moy[3])>>1) & 0xff3fcff;

    # le fond = le plus proche de la moyenne
    my($j, $jm, $d, $dm);
    for($dm=1e30, $j=0; $j<$glb_maxcol; ++$j) {
        if(($d = &irgb_dist($glb_pal[$j], $moy[0]))<$dm) {$dm =$d; $jm = $j;}
    }
    for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
        if(($d = &irgb_dist($glb_pal[$i], $moy[1]))<$dm) {$dm =$d; $im = $i;}
    }
    
    return ($glb_pal[$im], $glb_pal[$jm]);
}

sub couple5_ {
    my(@octet) = @_;
    
    # on commence un dither classique mais horizontal de l'octet
    my($i, $im, $j, $jm, $d, $dm, $rgb, @octet_pal);
    my(@dist) = (0) x ($glb_maxcol * 8);
    
    $#octet_pal = 7;
    for($i=0; $i<8; ++$i) {
        $rgb = $octet[$i];
        for($dm=1e30, $j=0; $j<$glb_maxcol; ++$j) {
            $d = &irgb_dist($glb_pal[$j], $rgb);
            if($d<$dm) {$dm = $d; $octet[$i] = $glb_pal[$octet_pal[$i] = $j];}
        }
        # $octet[$i+1] = &irgb_uadd($octet[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$octet_pal[$i]]), \@glb_map3)) if $i<7;
    }    
    # comptage des occurences
    $dm = -1; my(@cpt) = (0) x $glb_maxcol; my($filt_cpt) = 0;
    foreach $j (@octet_pal) {if(++$cpt[$j] > $dm) {$dm = $cpt[$jm = $j];}}
    if($dm >= 8) {
        $im = 0;
        print "*";
    } elsif($dm >= 0) {
        # une couleur domine de loin: on la prend en fond. On cherche
        # alors la forme qui minimise l'erreur sur l'octet d'origine
        $dm = 1e30; $im = 0; my($p) = 0;
        for($i = 0; $i < $glb_maxcol; ++$i) {
            $d  = $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
            $d += $dist[$p++];
 			if($d<$dm) {$dm = $d; $im = $i;}
        }
        print "#";
    } else {
        # on regroupe les pixels 2 par 2, on trouve le plus proche dans la palette
        @octet_pal = (0) x 4;
        for($i=0; $i<4; ++$i) {
            $rgb = (($octet[$i*2] + $octet[$i*2+1])>>1) & 0xff3fcff;
            for($dm=1e30, $j=0; $j<$glb_maxcol; ++$j) {
                $dist[$j*4 + $i] = $d = &irgb_dist($glb_pal[$j], $rgb);
                if($d<$dm) {$dm = $d; $octet_pal[$i] = $j;}
            }
        }
        # comptage des occurences
        $dm = -1; my(@cpt) = (0) x $glb_maxcol; my($filt_cpt) = 0;
        foreach $j (@octet_pal) {if(++$cpt[$j] > $dm) {$dm = $cpt[$jm = $j];}}
        if($dm >= 2) {
            $dm = 1e30; $im = 0; my($p) = $jm*4;
            for($i = 0; $i < $glb_maxcol; ++$i) {
                $p = $i * 4;
                $d  = $dist[$p++];
                $d += $dist[$p++] if $d < $dm;
                $d += $dist[$p++] if $d < $dm;
                $d += $dist[$p  ] if $d < $dm;
                if($d<$dm) {$dm = $d; $im = $i;}
            }
            print ":";
        } else {
            couple2(@octet) if 0;
            $dm = 1e30; $im = 0;
            for($i=0; $i<$glb_maxcol; ++$i) {
                for($j=0; $j<$i; ++$j) {
                    $d  = &couple_dist($i, $j, $octet_pal[0]);
                    $d += &couple_dist($i, $j, $octet_pal[1])  if $d<$dm;
                    $d += &couple_dist($i, $j, $octet_pal[2])  if $d<$dm;
                    $d += &couple_dist($i, $j, $octet_pal[3])  if $d<$dm;
           
                    if($d<$dm) {$dm = $d; $im = $i; $jm = $j;}
                }
            }
            print ".";
        }
    }
    print sprintf("%x%x ", $im, $jm); 
	return ($glb_pal[$im], $glb_pal[$jm]);
}

sub couple5 {
    my(@octet) = @_;

    my($i, $j, $rgb, $dm, @px);
    
    if(0) {
        # horiz dither first
        for($i=0; $i<8; ++$i) {
            $rgb = $octet[$i];
            for($j=0, $dm=1e30; $j<$glb_maxcol; ++$j) {
                $d = &irgb_dist($glb_pal[$j], $rgb);
                if($d<$dm) {$dm = $d; $octet[$i] = $glb_pal[$j];}
            }
            $octet[$i+1] = &irgb_uadd($octet[$i+1], &irgb_map(&irgb_sub($rgb, $octet[$i]), \@glb_map3)) if $i<7;
        }
    }
        
    foreach $j (@octet) {my @t = &irgb2rgb($j); push(@px, $t[0]*255, $t[1]*255, $t[2]*255);}
    
    my(@mean1) = (
        ($px[0] + $px[3] + $px[6] + $px[9]) / 4,
        ($px[1] + $px[4] + $px[7] + $px[10]) / 4,
        ($px[2] + $px[5] + $px[8] + $px[11]) / 4,
        ($px[12] + $px[15] + $px[18] + $px[21]) / 4,
        ($px[13] + $px[16] + $px[19] + $px[22]) / 4,
        ($px[14] + $px[17] + $px[20] + $px[23]) / 4,
    );
    my($d1, $d2, @mean2);
    
    # on trouve les deux clusters
    while(1) {
        #print join(",", @mean1),"\n";
        @mean2 = (0,0,0,0,0,0); $d1 = $d2 = 0;
        for($i=0; $i<8; ++$i) {
            @rgb = @px[($i*3)..($i*3+2)];
            if(&rgbdist(@mean1[0..2], @rgb) < &rgbdist(@mean1[3..5], @rgb)) {
                ++$d1; $mean2[0] += $rgb[0]; $mean2[1] += $rgb[1]; $mean2[2] += $rgb[2];
            } else {
                ++$d2; $mean2[3] += $rgb[0]; $mean2[4] += $rgb[1]; $mean2[5] += $rgb[2];
            }
        }
        # si un cluster est vide, on repart pour un tour
        if($d1 == 0) {
            # on trouve le point le plus eloigné  de l'autre centre
            @mean2 = (127, 127, 127, @mean2[3..5]);
        } elsif($d2 == 0) {
            @mean2 = (@mean2[0..2], 127, 127, 128);
        }
        
        $d1 = 1 unless $d1>0; $d2 = 1 unless $d2>0;
        $mean2[0] = int($mean2[0] / $d1); $mean2[1] = int($mean2[1] / $d1); $mean2[2] = int($mean2[2] / $d1);
        $mean2[3] = int($mean2[3] / $d2); $mean2[4] = int($mean2[4] / $d2); $mean2[5] = int($mean2[5] / $d2);

        last if $mean2[0]==$mean1[0] && $mean2[1]==$mean1[1] && $mean2[2]==$mean1[2] && $mean2[3]==$mean1[3] && $mean2[4]==$mean1[4] && $mean2[5]==$mean1[5];
        @mean1 = @mean2;
    }

    #print join(",", @mean1),"\n";
    my($mean) = ((($mean1[0]<<10) + $mean1[1])<<10) + $mean1[2];
    for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
        $d = &irgb_dist($mean, $glb_pal[$i]);
        if($d<$dm) {$dm = $d; $im = $i;}
    }
    $mean = ((($mean1[3]<<10) + $mean1[4])<<10) + $mean1[5];
    for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
        $d = &irgb_dist($mean, $glb_pal[$i]);
        if($d<$dm) {$dm = $d; $jm = $i;}
    }
    #print &irgb2hex($glb_pal[$im]), " ", &irgb2hex($glb_pal[$jm]),"\n";
    
    return ($glb_pal[$im], $glb_pal[$jm]);
}

sub rgbdist {
    my($r1, $g1, $b1, $r2, $g2, $b2) = @_;
    $r1 -= $r2;
    $g1 -= $g2;
    $b1 -= $b2;
    return sqrt($r1*$r1 + $g1*$g1 + $b1*$b1);
}

sub cleanup {
	return @_ if 0;
	my($thr) = $glb_clean;
	return @_ unless $thr>0;
	# on elimine les composantes plus faibles que 10% du max
	my(@t, $i, $t);
	for($i=0; $i<=$#_; $i+=8) {
		my($maxr, $maxv, $maxb) = (0, 0, 0);
		my($minr, $minv, $minb) = (1, 1, 1);
		my($rgb, @rgb);
		my(@o) = @_[$i..$i+7];
		for $rgb (@o) {
			@rgb = &irgb2rgb($rgb);
			$maxr = $rgb[0] if $rgb[0] > $maxr;
			$maxv = $rgb[1] if $rgb[1] > $maxv;
			$maxb = $rgb[2] if $rgb[2] > $maxb;
			$minr = $rgb[0] if $rgb[0] < $minr;
			$minv = $rgb[1] if $rgb[1] < $minv;
			$minb = $rgb[2] if $rgb[2] < $minb;
		}
		$maxr = (1-$thr)*$minr + $thr*$maxr;
		$maxv = (1-$thr)*$minv + $thr*$maxv;
		$maxb = (1-$thr)*$minb + $thr*$maxb;
		for $rgb (@o) {
			@rgb = &irgb2rgb($rgb);
			$rgb[0] = $minr if $rgb[0] < $maxr;
			$rgb[1] = $minv if $rgb[1] < $maxv;
			$rgb[2] = $minb if $rgb[2] < $maxb;
			#$rgb[0] = $maxr if $rgb[0] > $maxr;
			#$rgb[1] = $maxv if $rgb[1] > $maxv;
			#$rgb[2] = $maxb if $rgb[2] > $maxb;
			$t  = int($rgb[0]*255)&0x1ff; $t<<=10;
			$t += int($rgb[1]*255)&0x1ff; $t<<=10;
			$t += int($rgb[2]*255)&0x1ff;
			push(@t, $t);
		}
	}
	return @t;
}

sub couple6 {
    my(@octet) = @_;
    
    my($dbg) = 0;
    
    my($i, $im, $j, $jm, $d, $dm, $rgb, %cpt);
    my(@px) = (@octet);
    
    # dither de l'octet
    for($i=0; $i<8; ++$i) {
        $rgb = $px[$i];
        for($dm=1e30, $jm=$j=0; $j<$glb_maxcol; ++$j) {
            $d = &irgb_dist($glb_pal[$j], $rgb);
	    #print "$j => $d :: $jm\n";
            if($d<$dm) {$dm = $d; $jm = $j;}
        }
        ++$cpt{$jm};
	$px[$i+1] = &irgb_add($px[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$jm]), \@glb_map3)) if $i<7;
    }
    
    my(@cpt) = (sort { $cpt{$b} - $cpt{$a} } keys %cpt);
    
    if($dbg) {
	print "\n\n";
	for $t (@octet) {
		print &irgb2hex($t), " ";
	}
	print "\n\n";
	for $t (@cpt) {
		print &irgb2hex($glb_pal[$t]), " ", $cpt{$t}, "\n";
	}
    }
  
    # 1 ou 2 couls utilisées: pas de probs
    if($#cpt<=1) {
        print " ";
        # on s'assure qu'on en a au moins 2
        $cpt{$cpt[1] = 0} = 0 if $#cpt==0;

        return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);
    }
    
    # les 2 couls principales couvrent 7 pixels sur les 8
    if($cpt{$cpt[0]} + $cpt{$cpt[1]} >= 6) {
        print ".";
        return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);        
    }

    #return (0x0ff3fcff,0);
    
    if(0) {
        # on fusionne les couleurs voisines
        $rgb = 0x0c0300c0;
        for($i=$#cpt; $i>=0; --$i) {
            for($j=$i-1; $j>=0; --$j) {
                if(($rgb & $glb_pal[$cpt[$i]]) == ($rgb & $glb_pal[$cpt[$j]])) {
                    $cpt{$cpt[$j]} += $cpt{$cpt[$i]};
                    delete $cpt{$cpt[$i]}; print "*";
                    @cpt = (@cpt[0..$i-1], @cpt[$i+1..$#cpt]);
                    last;
                }
            }
        }
    
        @cpt = (sort { $cpt{$b} - $cpt{$a} } keys %cpt);
    
        # 1 ou 2 couls utilisées: pas de probs
        if($#cpt<=1) {
            print "_";
            # on s'assure qu'on en a au moins 2
            $cpt{$cpt[1] = 0} = 0 if $#cpt==0;

            return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);
        }
    
        # les 2 couls principales couvrent 7 pixels sur les 8
        if($cpt{$cpt[0]} + $cpt{$cpt[1]} >= 7) {
            print ":";
            return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);        
        }
    }
    
    # si la 1ere couvre 4 pixels, alors on prends la 2eme qui fait le moins d'err
    if($cpt{$cpt[0]} >= 6) {
        $jm = $cpt[0]; 
        for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
            next if $i==$jm;
            #next unless defined $cpt{$i};
	    $delta = 0;
            $d = 0; @px = (@octet);
            if(0) {
                foreach $j (@px) {$d += $glb_dist[$i*$glb_maxcol + $j] if $j!=$jm;}
            } elsif(0) {
                for($j = 0; $j<8 && $d<$dm; ++$j) {$d += &couple2_dist_sq($i, $jm, $octet[$j]);}
            } else {
                for($j = 0; $j<8 && $d<$dm; ++$j) {
                    $d1 = &irgb_dist($glb_pal[$i ], $px[$j]);
                    $d2 = &irgb_dist($glb_pal[$jm], $px[$j]);
		    if($d1 < $d2) {$d += &sq($d1); $rgb = $glb_pal[$i];} else {$d += &sq($d2); $rgb = $glb_pal[$jm];}
                    $px[$j+1] = &irgb_add($px[$j+1], &irgb_map(&irgb_sub($px[$j], $rgb), \@glb_map3)) if $glb_err3 && $j<7;
                }
		#$d += &irgb_module($delta);
            }
            if($d < $dm) {$dm = $d; $im = $i;}
        }
        print "o";
        return ($glb_pal[$im], $glb_pal[$jm]);
    }
    
    # TODO: prendre les couleurs les moins utilisées.. reduire leur résolution et voir si on peut les mapper
    # sur l'une des couleurs plus utilisée
    
    # fusionner les couleurs les plus proches: seuil = 1/16 au début, puis 1/8 après
    
    if(0) {
        # reduire la resolution de la palette de 0..255 à 0..7 pour merger les couleurs proches
        %cpt = (); @px = @octet; $msk = 0x0e0380e0;
        for($i=0; $i<8; ++$i) {
            $rgb = $px[$i] & $msk;
            for($dm=1e30, $jm=$j=0; $j<$glb_maxcol; ++$j) {
                $d = &irgb_dist($glb_pal[$j] & $msk, $rgb);
                if($d<$dm) {$dm = $d; $jm = $j;}
            }
            ++$cpt{$px[$i] = $jm};
            $px[$i+1] = &irgb_uadd($px[$i+1], &irgb_map(&irgb_sub($rgb, $glb_pal[$jm] & $msk), \@glb_map3)) if $glb_err3 &&  $i<7;
        }
        @cpt = (sort { $cpt{$b} - $cpt{$a} } keys %cpt);

        if($#cpt<=1) {
            # on s'assure qu'on en a au moins 2
            $cpt{$cpt[1] = 0} = 0 if $#cpt==0;
            print "_";
            return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);
        }
    
        # les 2 couls principales couvrent 7 pixels sur les 8 (plus strict)
        if($cpt{$cpt[0]} + $cpt{$cpt[1]} >= 7) {
            print ":";
            return ($glb_pal[$cpt[1]], $glb_pal[$cpt[0]]);        
        }
    }
    
    if(0) {
        # utilisation de rayons
        for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
            for($j=0; $j<$glb_maxcol; ++$j) {
                @px = @octet; $d = 0; $ir = $jr = 0;
                for($k = 0; $k<8 && $d<$dm; ++$k) {
	    
                    $di = &irgb_dist($glb_pal[$i], $px[$k]);
                    $dj = &irgb_dist($glb_pal[$j], $px[$k]);
                    if($di <= $dj) {
                        $ir = $di if $di>$ir;
                        $rgb = $glb_pal[$i];
                    } else {
                        $jr = $dj if $dj>$jr;
                        $rgb = $glb_pal[$j];
                    }
                    $d = $ir + $jr;
                    $px[$i+1] = &irgb_uadd($px[$i+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $i<7;
                }
                if($d < $dm) {$dm = $d; $im = $i; $jm = $j}
            }
        }
        print "#";
        return ($glb_pal[$im], $glb_pal[$jm]);
    }
        
    # sinon tester tous les couple avec dither
    my($r, $rm);
    for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
        #next unless defined $cpt{$i};
        for($j=0; $j<$i; ++$j) {
            next unless defined $cpt{$j};
            @px = (@octet);
            #print $i,",",$j, "##", &irgb2hex($glb_pal[$i])," ",&irgb2hex($glb_pal[$j]),"\n";
	    #for($k=0; $k<8; ++$k) {print " ", &irgb2hex($px[$k]);} print "\n";
	    for($r = $d = $k = 0; $k<8 && $d<$dm; ++$k) {
		$di = &irgb_dist($glb_pal[$i], $px[$k]);
                $dj = &irgb_dist($glb_pal[$j], $px[$k]);
                if($di <= $dj) {
                    $r |= 1;
                    $rgb = $glb_pal[$i];
		    $d += &sq($di);
                } else {
                    $r |= 2;
                    $rgb = $glb_pal[$j];
		    $d += &sq($dj);
                }
		#print $k,"->", &irgb2hex($octet[$k]), ":", &irgb2hex($rgb),"=",$d,"\n";
                $px[$k+1] = &irgb_add($px[$k+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $k<7;
            }
	    #print "DDDDD ",irgb2hex($delta),"\n";
	    #$d += &irgb_module($delta);
	    #print $i,",",$j, "==", &irgb2hex($glb_pal[$i])," ",&irgb2hex($glb_pal[$j])," == ",$d," (",$dm,")\n";
            if($d < $dm) {$rm = $r; $dm = $d; $im = $i; $jm = $j}
        }
    }
    
    if($rm == 3) {
        print "#";
	#print "==> ", $im, ",", $jm, " ",&irgb2hex($glb_pal[$im])," ",&irgb2hex($glb_pal[$jm]),"\n";
        return ($glb_pal[$im], $glb_pal[$jm]);
    }
    
    # si en fait on a qu'une seule couleur reele (parce que la palette
    # n'est pas assez discriminante par exemple), alors on prend la couleur
    # la plus frequente, et on cherche la coul realisant la plus petite erreur
    if($rm != 3) {
        $jm = $cpt[0]; 
        for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
            next if $i==$jm;
            @px = (@octet);
            for($d = $j = 0; $j<8 && $d<$dm; ++$j) {
                $d1 = &irgb_dist($glb_pal[$i ], $px[$j]);
                $d2 = &irgb_dist($glb_pal[$jm], $px[$j]);
                if($d1<$d2) {$rgb = $glb_pal[$i]; $d += &sq($d1);} else {$rgb = $glb_pal[$jm]; $d += &sq($d2);}
                $px[$j+1] = &irgb_add($px[$j+1], &irgb_map(&irgb_sub($px[$j], $rgb), \@glb_map3)) if $glb_err3 && $j<7;
            }
            if($d < $dm) {$dm = $d; $im = $i;}
        }
        #print $cpt{$cpt[0]}," $dm\n";
        return ($glb_pal[$im], $glb_pal[$jm]);
    }
    
    
    if(0) {
    print "#$dm\n";
    
    ### on vérifie que le couple est bien utilisé
    @px = (@octet); $r = 0;
    for($k = 0; $k<8; ++$k) {
        $di = &irgb_dist($glb_pal[$im], $px[$k]);
        $dj = &irgb_dist($glb_pal[$jm], $px[$k]);
        if($di <= $dj) {
                    $rgb = $glb_pal[$im]; 
                    $r |= 1;
        } else {
                    $rgb = $glb_pal[$jm];
                    $r |= 2;
        }
        $px[$k+1] = &irgb_add($px[$k+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $k<7;
    }
    
    if($r!=3) {
        print "\n\n";
        for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
            for($j=0; $j<=$i; ++$j) {
                @px = (@octet);
                for($d = $k = 0; $k<8 && $d<$dm; ++$k) {
                    $di = &irgb_dist($glb_pal[$i], $px[$k]);
                    $dj = &irgb_dist($glb_pal[$j], $px[$k]);
                    if($di <= $dj) {
                        $d += &sq($di);
                        $rgb = $glb_pal[$i];
                    } else {
                        $d += &sq($dj);
                        $rgb = $glb_pal[$j];
                    }
                    $px[$k+1] = &irgb_add($px[$k+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $k<7;
                }
                print "$i,$j ==> $d\n";
                if($d < $dm) {print "^^^\n"; $dm = $d; $im = $i; $jm = $j}
            }
        }
        print "\n\n";
        @px = (@octet); $r = 0;
        for($d = $k = 0; $k<8; ++$k) {
            $di = &irgb_dist($glb_pal[$im], $px[$k]);
            $dj = &irgb_dist($glb_pal[$jm], $px[$k]);
            if($di <= $dj) {
                $d += $di;
                $rgb = $glb_pal[$im]; 
                $r |= 1;
            } else {
                $rgb = $glb_pal[$jm];
                $r |= 2;
            }
            print &irgb2hex($px[$k]),"=>$di,$dj=>",&irgb2hex($rgb),"\n";
            $px[$k+1] = &irgb_add($px[$k+1], &irgb_map(&irgb_sub($px[$k], $rgb), \@glb_map3)) if $glb_err3 && $k<7;
        }
        die;
    }
    }
 
    print "#";
    return ($glb_pal[$im], $glb_pal[$jm]);
}

sub sq {
    return $_[0]*$_[0];
}

sub xint {
	if(0) {
    # round to even?
    my($t) = @_;
    # round to even
    my($halfway) = int($t*2)==$t*2;
    if($t>=0) {$t = int($t + 0.5);} else {$t = int($t - 0.5);}
    if($halfway) {$t = int($t/2)*2;}
    return $t;
    }

    return   int($_[0]);
    return   int(0.5 + $_[0]) if $_[0]>=0;
    return - int(0.5 - $_[0]);
}

sub write_map {
    my($name, $ram_ab, @px) = @_;
    
    my($i, $t);
    
    # récupération de la palette RGB
    my(%pal);
    foreach $i (@px) {++$pal{$i};}   
    #my(@t) = (sort { $pal{$b} - $pal{$a} } keys %pal);
    my(@t) = (sort { &irgb_module($a) - &irgb_module($b) } keys %pal);
	die "trop de couleurs" if $#t>15;
    @t = (@t, (0) x 15)[0..15];
    
    # pour le tour on utilise la couleur la plus sombre
    @t = ($t[0], $t[15], @t[1..14]);
    my($tour) = 0;
    for($i=0; $i<15; ++$i)  {
        $tour = $i if &irgb_module($t[$i])<&irgb_module($t[$tour]);
    }
    
    # pour que l'afficheur de préhisto marche, il faut que le tour soit 
    # d'indexe fixe. On fait en sorte que ce soit toujours 0
    if($tour != 0) {
	my($t) = $t[$tour];
	$t[$tour] = $t[0];
	$t[0] = $t;
	$tour = 0;
    }
    
    # conversion de la palette vers les intensités thomson
    my(@pal, %rgb2pal);
    if($glb_to7pal) {
        @t = &to770_palette;
        for($i=0; $i<=$#t; ++$i) {$rgb2pal{$t[$i]} = $i;}
    } elsif($#map_ef>=0) {
        foreach $i (@t) {
            $rgb2pal{$i} = ($#pal + 1)>>1;
            
            #print &irgb2hex($i),":";
            my($v, $j, $d, $m, $p);
            
            $v = $i & 255; $i>>=10; #print "$v ";
            for($m=1e30, $j = 0; $j<=$#ef_vals; ++$j) {
                $d = $ef_vals[$j] - $v; $d = -$d if $d<0;
                if($d<$m) {$m = $d; $p = $j;}
            }
            my($b) = $p;
            $v = $i & 255; $i>>=10; #print "$v ";
            for($m=1e30, $j = 0; $j<=$#ef_vals; ++$j) {
                $d = $ef_vals[$j] - $v; $d = -$d if $d<0;
                if($d<$m) {$m = $d; $p = $j;}
            }
            my($g) = $p;
            $v = $i & 255; $i>>=10; #print "$v ";
            for($m=1e30, $j = 0; $j<=$#ef_vals; ++$j) {
                $d = $ef_vals[$j] - $v; $d = -$d if $d<0;
                if($d<$m) {$m = $d; $p = $j;}
            }
            my($r) = $p;
            
            push(@pal, $b, $g*16 + $r);
            #print sprintf("%x%x%x,", $b,$g,$r);
        }
    } else {
        foreach $i (@t) {
            $rgb2pal{$i} = ($#pal + 1)>>1;

            my($r, $g, $b) = &irgb2rgb($i);
            push(@pal, int($b*15), int($g*15)*16 + int($r*15));
        }
    }
    @t = ();
    
    # construction rama / ramb
    my(@rama, @ramb);
    my($idx, @cols) = (0) x 81;
    for($i=0; $i<$#px; $i += 8) {
        my(@octet) = @px[$i..($i+7)];
        # on trouve les deux couleurs
        my(%col) = ();
        foreach $t (@octet) {$col{$t} = 1;}
        @t = keys %col;
        die "trop de couleur pour l'octet" if $#t>1;
	
        # 1 seule couleur.. on essaye de récuperer les couleurs de la ligne d'avant si possible
        if($#t==0) {
            if($t[0] == $cols[$idx]) {
                $t[1] = $cols[$idx+1];
            } elsif($t[0] == $cols[$idx+1]) {
                $t[1] = $cols[$idx];
            } else {
                $t[1] = 7;
            }
        }
	
        @cols[$idx..$idx+1] = @t;
        $idx=0 if ($idx+=2)==80;

        my($forme, $fond) = ($t[0], $t[1]);
	
        %col = ();
        # pour l'instant 
        $t = 0;
        for($j=0; $j<8; ++$j) {
            $t += (128>>$j) if $octet[$j]!=$fond;
        }
	
        $forme = $rgb2pal{$forme};
        $fond = $rgb2pal{$fond};
        # pour favoriser les répétitions en ramb, on fait $forme>=$fond
        if($forme >= $fond) {
	    push(@rama, $t);
            push(@ramb, ($forme * 8 + ($fond&7) + ($fond & 8)*16) ^ (128+64));
        } else {
            push(@rama, $t^255);
            push(@ramb, ($fond * 8 + ($forme&7) + ($forme & 8)*16) ^ (128+64));
        }
    }
    
    # compression à proprement parler
    my(@data);
    push(@data, 
        # bm 40
        0,
        # ncols-1
        39,
        # nlines-1
        24);
	push(@data,
        # ram a
        &to7_comp(@rama),
        0, 0) if $ram_ab & 1;
	push(@data,
        # ram b
        &to7_comp(@ramb),
        0, 0) if $ram_ab & 2;
    
    # if faut aligner l'extension sur une addr paire
    push(@data, 0) unless $#data & 1;
    
    push(@data,
        # to-snap
        0, 0, 0, $tour, 0, 0, @pal, 0xa5, 0x5a) unless $glb_to7pal;

    # ecriture fichier binaire
    open(OUT, ">$name"); 
    print OUT pack('C*', 0, int((1+$#data)/256), (1+$#data)&255, 0, 0);
    print OUT pack('C*', @data);
    print OUT pack('C*', 255, 0, 0, 0, 0);
    close(OUT);
}

sub to7_comp {
    my(@data) = @_;
    my(@result, @partial);
    
    for(my $p=0; $p<8000; ++$p) {
        # on lit car num fois
        my($num, $car) = (1, $data[($p % 200)*40 + int($p/200)]);
        while($num<255 && $p+1<8000 && $data[(($p+1) % 200)*40 + int(($p+1)/200)]==$car) {++$p; ++$num;}
        my($default) = 1;
        if($#partial>$[) {
            # 01 aa 01 bb ==> 00 02 aa bb
            if($default && $num==1 && $partial[0]==1) {@partial = (00, 02, $partial[1], $car); $default = 0;}
            # 00 n xx xx xx 01 bb ==> 00 n+1 xx xx xx bb
            if($default && $num==1 && $partial[0]==0 && $partial[1]<255) {push(@partial, $car); $partial[1]++; $default = 0;}
            # 00 n xx xx xx 02 bb ==> 00 n+2 xx xx xx bb bb (pas utile mais sert quand combiné à la regle ci-dessus)
            if($default && $num==2 && $partial[0]==0 && $partial[1]<254) {push(@partial, $car, $car); $partial[1]+=2; $default = 0;}
            # 01 aa 02 bb ==> 00 03 aa bb bb
        }         
        if($default) {push(@result, @partial); @partial = ($num, $car);}
    }
    push(@result, @partial);
    
    return @result;
}

sub wd_file {
	return ".watchdog";
}

sub reset_wd {
	unlink &wd_file;
}

sub start_wd {
	my($pause) = 300;
	my($child) = fork;
	die "fork failed" unless defined $child;
	return unless $child;
	while(1) {
		sleep($pause);
		my($f) = &wd_file;
		if(-f $f) {
			&reset_wd;
			kill 9, $child;
			die "Watch dog detected inactivity for $pause sec, exiting";
		} else {
			open(WDFILE,">$f");close(WDFILE);
		}
	}
}
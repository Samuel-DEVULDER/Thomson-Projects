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
$glb_extin  = 0.9;
$glb_pause = $glb_to7_pal ? 5 : 7;
    
# error dispersion matrix. Index represents:
#       X 0
#     1 2    
# 3 = 0 + 1 + 2
@glb_ostro = (
    13,     0,     5,    18,     # /*    0 */
    13,     0,     5,    18,     # /*    1 */
    21,     0,    10,    31,     # /*    2 */
     7,     0,     4,    11,     # /*    3 */
     8,     0,     5,    13,     # /*    4 */
    47,     3,    28,    78,     # /*    5 */
    23,     3,    13,    39,     # /*    6 */
    15,     3,     8,    26,     # /*    7 */
    22,     6,    11,    39,     # /*    8 */
    43,    15,    20,    78,     # /*    9 */
     7,     3,     3,    13,     # /*   10 */
   501,   224,   211,   936,     # /*   11 */
   249,   116,   103,   468,     # /*   12 */
   165,    80,    67,   312,     # /*   13 */
   123,    62,    49,   234,     # /*   14 */
   489,   256,   191,   936,     # /*   15 */
    81,    44,    31,   156,     # /*   16 */
   483,   272,   181,   936,     # /*   17 */
    60,    35,    22,   117,     # /*   18 */
    53,    32,    19,   104,     # /*   19 */
   237,   148,    83,   468,     # /*   20 */
   471,   304,   161,   936,     # /*   21 */
     3,     2,     1,     6,     # /*   22 */
   459,   304,   161,   924,     # /*   23 */
    38,    25,    14,    77,     # /*   24 */
   453,   296,   175,   924,     # /*   25 */
   225,   146,    91,   462,     # /*   26 */
   149,    96,    63,   308,     # /*   27 */
   111,    71,    49,   231,     # /*   28 */
    63,    40,    29,   132,     # /*   29 */
    73,    46,    35,   154,     # /*   30 */
   435,   272,   217,   924,     # /*   31 */
   108,    67,    56,   231,     # /*   32 */
    13,     8,     7,    28,     # /*   33 */
   213,   130,   119,   462,     # /*   34 */
   423,   256,   245,   924,     # /*   35 */
     5,     3,     3,    11,     # /*   36 */
   281,   173,   162,   616,     # /*   37 */
   141,    89,    78,   308,     # /*   38 */
   283,   183,   150,   616,     # /*   39 */
    71,    47,    36,   154,     # /*   40 */
   285,   193,   138,   616,     # /*   41 */
    13,     9,     6,    28,     # /*   42 */
    41,    29,    18,    88,     # /*   43 */
    36,    26,    15,    77,     # /*   44 */
   289,   213,   114,   616,     # /*   45 */
   145,   109,    54,   308,     # /*   46 */
   291,   223,   102,   616,     # /*   47 */
    73,    57,    24,   154,     # /*   48 */
   293,   233,    90,   616,     # /*   49 */
    21,    17,     6,    44,     # /*   50 */
   295,   243,    78,   616,     # /*   51 */
    37,    31,     9,    77,     # /*   52 */
    27,    23,     6,    56,     # /*   53 */
   149,   129,    30,   308,     # /*   54 */
   299,   263,    54,   616,     # /*   55 */
    75,    67,    12,   154,     # /*   56 */
    43,    39,     6,    88,     # /*   57 */
   151,   139,    18,   308,     # /*   58 */
   303,   283,    30,   616,     # /*   59 */
    38,    36,     3,    77,     # /*   60 */
   305,   293,    18,   616,     # /*   61 */
   153,   149,     6,   308,     # /*   62 */
   307,   303,     6,   616,     # /*   63 */
     1,     1,     0,     2,     # /*   64 */
   101,   105,     2,   208,     # /*   65 */
    49,    53,     2,   104,     # /*   66 */
    95,   107,     6,   208,     # /*   67 */
    23,    27,     2,    52,     # /*   68 */
    89,   109,    10,   208,     # /*   69 */
    43,    55,     6,   104,     # /*   70 */
    83,   111,    14,   208,     # /*   71 */
     5,     7,     1,    13,     # /*   72 */
   172,   181,    37,   390,     # /*   73 */
    97,    76,    22,   195,     # /*   74 */
    72,    41,    17,   130,     # /*   75 */
   119,    47,    29,   195,     # /*   76 */
     4,     1,     1,     6,     # /*   77 */
     4,     1,     1,     6,     # /*   78 */
     4,     1,     1,     6,     # /*   79 */
     4,     1,     1,     6,     # /*   80 */
     4,     1,     1,     6,     # /*   81 */
     4,     1,     1,     6,     # /*   82 */
     4,     1,     1,     6,     # /*   83 */
     4,     1,     1,     6,     # /*   84 */
     4,     1,     1,     6,     # /*   85 */
    65,    18,    17,   100,     # /*   86 */
    95,    29,    26,   150,     # /*   87 */
   185,    62,    53,   300,     # /*   88 */
    30,    11,     9,    50,     # /*   89 */
    35,    14,    11,    60,     # /*   90 */
    85,    37,    28,   150,     # /*   91 */
    55,    26,    19,   100,     # /*   92 */
    80,    41,    29,   150,     # /*   93 */
   155,    86,    59,   300,     # /*   94 */
     5,     3,     2,    10,     # /*   95 */
     5,     3,     2,    10,     # /*   96 */
     5,     3,     2,    10,     # /*   97 */
     5,     3,     2,    10,     # /*   98 */
     5,     3,     2,    10,     # /*   99 */
     5,     3,     2,    10,     # /*  100 */
     5,     3,     2,    10,     # /*  101 */
     5,     3,     2,    10,     # /*  102 */
     5,     3,     2,    10,     # /*  103 */
     5,     3,     2,    10,     # /*  104 */
     5,     3,     2,    10,     # /*  105 */
     5,     3,     2,    10,     # /*  106 */
     5,     3,     2,    10,     # /*  107 */
   305,   176,   119,   600,     # /*  108 */
   155,    86,    59,   300,     # /*  109 */
   105,    56,    39,   200,     # /*  110 */
    80,    41,    29,   150,     # /*  111 */
    65,    32,    23,   120,     # /*  112 */
    55,    26,    19,   100,     # /*  113 */
   335,   152,   113,   600,     # /*  114 */
    85,    37,    28,   150,     # /*  115 */
   115,    48,    37,   200,     # /*  116 */
    35,    14,    11,    60,     # /*  117 */
   355,   136,   109,   600,     # /*  118 */
    30,    11,     9,    50,     # /*  119 */
   365,   128,   107,   600,     # /*  120 */
   185,    62,    53,   300,     # /*  121 */
    25,     8,     7,    40,     # /*  122 */
    95,    29,    26,   150,     # /*  123 */
   385,   112,   103,   600,     # /*  124 */
    65,    18,    17,   100,     # /*  125 */
   395,   104,   101,   600,     # /*  126 */
     4,     1,     1,     6,     # /*  127 */
     4,     1,     1,     6,     # /*  128 */
   395,   104,   101,   600,     # /*  129 */
    65,    18,    17,   100,     # /*  130 */
   385,   112,   103,   600,     # /*  131 */
    95,    29,    26,   150,     # /*  132 */
    25,     8,     7,    40,     # /*  133 */
   185,    62,    53,   300,     # /*  134 */
   365,   128,   107,   600,     # /*  135 */
    30,    11,     9,    50,     # /*  136 */
   355,   136,   109,   600,     # /*  137 */
    35,    14,    11,    60,     # /*  138 */
   115,    48,    37,   200,     # /*  139 */
    85,    37,    28,   150,     # /*  140 */
   335,   152,   113,   600,     # /*  141 */
    55,    26,    19,   100,     # /*  142 */
    65,    32,    23,   120,     # /*  143 */
    80,    41,    29,   150,     # /*  144 */
   105,    56,    39,   200,     # /*  145 */
   155,    86,    59,   300,     # /*  146 */
   305,   176,   119,   600,     # /*  147 */
     5,     3,     2,    10,     # /*  148 */
     5,     3,     2,    10,     # /*  149 */
     5,     3,     2,    10,     # /*  150 */
     5,     3,     2,    10,     # /*  151 */
     5,     3,     2,    10,     # /*  152 */
     5,     3,     2,    10,     # /*  153 */
     5,     3,     2,    10,     # /*  154 */
     5,     3,     2,    10,     # /*  155 */
     5,     3,     2,    10,     # /*  156 */
     5,     3,     2,    10,     # /*  157 */
     5,     3,     2,    10,     # /*  158 */
     5,     3,     2,    10,     # /*  159 */
     5,     3,     2,    10,     # /*  160 */
   155,    86,    59,   300,     # /*  161 */
    80,    41,    29,   150,     # /*  162 */
    55,    26,    19,   100,     # /*  163 */
    85,    37,    28,   150,     # /*  164 */
    35,    14,    11,    60,     # /*  165 */
    30,    11,     9,    50,     # /*  166 */
   185,    62,    53,   300,     # /*  167 */
    95,    29,    26,   150,     # /*  168 */
    65,    18,    17,   100,     # /*  169 */
     4,     1,     1,     6,     # /*  170 */
     4,     1,     1,     6,     # /*  171 */
     4,     1,     1,     6,     # /*  172 */
     4,     1,     1,     6,     # /*  173 */
     4,     1,     1,     6,     # /*  174 */
     4,     1,     1,     6,     # /*  175 */
     4,     1,     1,     6,     # /*  176 */
     4,     1,     1,     6,     # /*  177 */
     4,     1,     1,     6,     # /*  178 */
   119,    47,    29,   195,     # /*  179 */
    72,    41,    17,   130,     # /*  180 */
    97,    76,    22,   195,     # /*  181 */
   172,   181,    37,   390,     # /*  182 */
     5,     7,     1,    13,     # /*  183 */
    83,   111,    14,   208,     # /*  184 */
    43,    55,     6,   104,     # /*  185 */
    89,   109,    10,   208,     # /*  186 */
    23,    27,     2,    52,     # /*  187 */
    95,   107,     6,   208,     # /*  188 */
    49,    53,     2,   104,     # /*  189 */
   101,   105,     2,   208,     # /*  190 */
     1,     1,     0,     2,     # /*  191 */
   307,   303,     6,   616,     # /*  192 */
   153,   149,     6,   308,     # /*  193 */
   305,   293,    18,   616,     # /*  194 */
    38,    36,     3,    77,     # /*  195 */
   303,   283,    30,   616,     # /*  196 */
   151,   139,    18,   308,     # /*  197 */
    43,    39,     6,    88,     # /*  198 */
    75,    67,    12,   154,     # /*  199 */
   299,   263,    54,   616,     # /*  200 */
   149,   129,    30,   308,     # /*  201 */
    27,    23,     6,    56,     # /*  202 */
    37,    31,     9,    77,     # /*  203 */
   295,   243,    78,   616,     # /*  204 */
    21,    17,     6,    44,     # /*  205 */
   293,   233,    90,   616,     # /*  206 */
    73,    57,    24,   154,     # /*  207 */
   291,   223,   102,   616,     # /*  208 */
   145,   109,    54,   308,     # /*  209 */
   289,   213,   114,   616,     # /*  210 */
    36,    26,    15,    77,     # /*  211 */
    41,    29,    18,    88,     # /*  212 */
    13,     9,     6,    28,     # /*  213 */
   285,   193,   138,   616,     # /*  214 */
    71,    47,    36,   154,     # /*  215 */
   283,   183,   150,   616,     # /*  216 */
   141,    89,    78,   308,     # /*  217 */
   281,   173,   162,   616,     # /*  218 */
     5,     3,     3,    11,     # /*  219 */
   423,   256,   245,   924,     # /*  220 */
   213,   130,   119,   462,     # /*  221 */
    13,     8,     7,    28,     # /*  222 */
   108,    67,    56,   231,     # /*  223 */
   435,   272,   217,   924,     # /*  224 */
    73,    46,    35,   154,     # /*  225 */
    63,    40,    29,   132,     # /*  226 */
   111,    71,    49,   231,     # /*  227 */
   149,    96,    63,   308,     # /*  228 */
   225,   146,    91,   462,     # /*  229 */
   453,   296,   175,   924,     # /*  230 */
    38,    25,    14,    77,     # /*  231 */
   459,   304,   161,   924,     # /*  232 */
     3,     2,     1,     6,     # /*  233 */
   471,   304,   161,   936,     # /*  234 */
   237,   148,    83,   468,     # /*  235 */
    53,    32,    19,   104,     # /*  236 */
    60,    35,    22,   117,     # /*  237 */
   483,   272,   181,   936,     # /*  238 */
    81,    44,    31,   156,     # /*  239 */
   489,   256,   191,   936,     # /*  240 */
   123,    62,    49,   234,     # /*  241 */
   165,    80,    67,   312,     # /*  242 */
   249,   116,   103,   468,     # /*  243 */
   501,   224,   211,   936,     # /*  244 */
     7,     3,     3,    13,     # /*  245 */
    43,    15,    20,    78,     # /*  246 */
    22,     6,    11,    39,     # /*  247 */
    15,     3,     8,    26,     # /*  248 */
    23,     3,    13,    39,     # /*  249 */
    47,     3,    28,    78,     # /*  250 */
     8,     0,     5,    13,     # /*  251 */
     7,     0,     4,    11,     # /*  252 */
    21,     0,    10,    31,     # /*  253 */
    13,     0,     5,    18,     # /*  254 */
    13,     0,     5,    18);
    
#   X 2
# 0 1
@glb_ostr0 = ();
@glb_ostr1 = ();
@glb_ostr2 = ();
for($j = 0; $j<256; ++$j) {
	my(@t) = (0) x 512;
	
	for($i = -256; $i<256; ++$i) {$t[$i & 0x1ff] = &err_trunc($i, $glb_extin * $glb_ostro[4*$j+1] * 1.0 / $glb_ostro[4*$j+3]) & 0x1ff;} 
	$glb_ostr0[$j] = [@t];
	
	for($i = -256; $i<256; ++$i) {$t[$i & 0x1ff] = &err_trunc($i, $glb_extin * $glb_ostro[4*$j+2] * 1.0 / $glb_ostro[4*$j+3]) & 0x1ff;} 
	$glb_ostr1[$j] = [@t];

	for($i = -256; $i<256; ++$i) {$t[$i & 0x1ff] = &err_trunc($i, $glb_extin * $glb_ostro[4*$j+0] * 1.0 / $glb_ostro[4*$j+3]) & 0x1ff;} 
	$glb_ostr2[$j] = [@t];
}

# construit les maps pour la multiplication
for($i = -256; $i<256; ++$i) {$glb_sqr [$i & 0x1ff] = $i * $i;}

# limit error
$clamp = -48;
for($i = -256; $i<256; ++$i) {$glb_clamp[$i & 0x1ff] = ($i< $clamp ? $clamp : $i) & 0x1ff;}

# map une intensité entre 0..255 vers l'intensité produite par le circuit EFxxx le plus proche (16 valeurs)
@ef_vals = (0, 39, 74, 101, 122, 140, 157, 171, 185, 195, 206, 216, 227, 237, 248, 255) if 1;

# eval perso
@ef_vals = (0,78,116,138,157,171,182,187,205,215,222,229,238,244,249,255) if 0;
@ef_vals = (0,51,91,117,142,161,172,187,199,210,220,227,236,244,248,255) if 1;

# ef TEO
@ef_vals = (0, 100, 127, 142, 163, 179, 191, 203, 215, 223, 231, 239, 243, 247, 251, 255) if 1;
@ef_vals = (0, 127, 169, 188, 198, 205, 212, 219, 223, 227, 232, 239, 243, 247, 251, 255) if 0; # eval prehisto
@ef_vals = (0, 174, 192, 203, 211, 218, 224, 229, 233, 237, 240, 244, 247, 249, 252, 255) if 0; # prehisto 2
@ef_vals = (0, 169, 188, 200, 209, 216, 222, 227, 232, 236, 239, 243, 246, 249, 252, 255) if 0; # prehisto 3
@ef_vals = (0, 153, 175, 189, 199, 207, 215, 221, 227, 232, 236, 241, 245, 248, 252, 255) if 0; # prehisto 4

@intens = @ef_vals;

if($glb_gamma) {
	#print join(",", @intens), "\n";
	foreach (@intens)  {$_ = &gamma($_);}
	#print join(",", @intens), "\n";
	foreach (@ef_vals) {$_ = &gamma($_);}
}

# index
@glb_sprd_idx = ();
$k=0;
for($i=0; $i<256; ++$i) {
	$glb_sprd_idx[$i] = $i; next;
	++$k if $k<$#ef_vals && $i==$ef_vals[$k+1];
	$glb_sprd_idx[$i] = xint(($i - $ef_vals[$k])*256/($ef_vals[$k+1]-$ef_vals[$k]));
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
$stopme = "rgb/.stop_me";
open(FILE, ">$stopme"); close(FILE);

&start_wd;

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
	$out = "rgb/$out";

	print $cpt,"/",1+$#files," $in => $out\n";
	
	&reset_wd;
	
	$t = $out; $t =~ s/.gif$/.MAP/;
	#next if -e $out || -e $t;
	next if -e $t;

	# lecture
	my(@px) = &read_image($in);	
	
	@px = &cleanup(@px) if 1;

	# creation palette 16 couls (passage par une globale pour simplifier le code)
	@glb_pal = &find_palette($glb_maxcol, @px);
	
	#&simple_dither_pal(1, @px);
	#simple_dither_wpal(1, 1+$#glb_pal, @glb_pal, @px);
	
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
    
	# process image
	my($p, $y, $x) = (0,0,0);
	my($forme, $fond);
			
	for($y=0; $y<200; ++$y) {
		print "\r> ", int($y/2), "%  ";
		
		my($x0, $x1, $inc) = (319, -1, -1);
		($x0, $x1, $inc) = (0, 320, 1) unless $y & 1;
		
		for($x=$x0; $x!=$x1;) {
			$p = $y * 320 + $x;
			
			#for($i=0; $i<8; ++$i) {$px[$p+$i] = &irgb_map($px[$p+$i], \@glb_clamp);}
			if($inc>0) {
				for($i=0; $i<8; ++$i) {$px[$p+$i] = &irgb_sat($px[$p+$i]);}
				($forme, $fond) = &couple6(@px[$p+0,$p+1,$p+2,$p+3,$p+4,$p+5,$p+6,$p+7]);
			} else {
				for($i=0; $i<8; ++$i) {$px[$p-$i] = &irgb_sat($px[$p-$i]);}
				($forme, $fond) = &couple6(@px[$p-0,$p-1,$p-2,$p-3,$p-4,$p-5,$p-6,$p-7]);
			}
			
			
			#print "===> ", &irgb2hex($forme), " ", &irgb2hex($fond),"\n";
			my($blk) = 8;
			for($i=0; $i<$blk; ++$i) {
				my($rvb) = &irgb_sat($px[$p]);
				
				if($blk==2) {
				my($fr,$fg,$fb) = &irgb2rgb($rvb);
				$fr = int(($fr+0.5))*255;
				$fg = int(($fg+0.5))*255;
				$fb = int(($fb+0.5))*255;
				$px[$p] = ((($fr<<10) + $fg)<<10) + $fb;
				} else {
				# meilleur couleur approchante
				$px[$p] = (&irgb_dist($forme, $rvb) < &irgb_dist($fond, $rvb)) ? $forme : $fond;
				}
				
				# diffusion d'erreur
				my($err) = &irgb_sub($rvb, $px[$p]);
					
				if($inc>0) {
					$px[$p + 319] = &irgb_sprd($px[$p + 319], $err, $rvb, \@glb_ostr0) if $y<199 && $x>0;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $err, $rvb, \@glb_ostr1) if $y<199;
					$px[$p + 001] = &irgb_sprd($px[$p + 001], $err, $rvb, \@glb_ostr2) if           $x<319;
				} else {
					$px[$p + 321] = &irgb_sprd($px[$p + 321], $err, $rvb, \@glb_ostr0) if $y<199 && $x<319;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $err, $rvb, \@glb_ostr1) if $y<199;
					$px[$p - 001] = &irgb_sprd($px[$p - 001], $err, $rvb, \@glb_ostr2) if           $x>0;
				}
				# pour voir 	les limites octets
				$px[$p] = $i&1? $forme : $fond if 0;
				$px[$p] ^= 0x0ff3fcff if $i==0 && 0;
				
				#die "$x, $i, $y inc=$inc $p $#px" if $#px>=64000;
				
				$p += $inc;
				$x += $inc;
			}
			
		}
		$| = 1; print "\r"; $| = 0;
	}
	%dist_cache = ();
	
	# ecriture des pixels et lecture
	#$out =~ s/.gif$/.c16.gif/;
	#&write_image($out, @px);
    
	$out =~ s/.gif$/.MAP/;
	&write_map($out, @px);
	$| = 1; print "                                                             \r"; $| = 0;
	sleep($glb_pause);
}
unlink($stopme);

if(0) {
	%m = ();
	foreach $out (<rgb# /*.MAP>) {
		open(IN, "cygpath -w -s \"$out\" |"); $zz = <IN>; chomp($zz); close(IN);
		$zz=~y/~\\/_\//;
		$m{$out} = $zz;
	}
	foreach $out (keys %m) {
		rename($out, $m{$out});
	}
}

exit;

sub err_trunc {
	my($err, $coef) = @_;
	#$err = 0 if $err>-10 && $err<10;
	return &xint($err * $coef);
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
    my($t,@t);
    for $t (0x000,0x00F,0x0F0,0x0FF,0xF00,0xF0F,0xFF0,0xFFF,
	    0x777,0x33A,0x3A3,0x3AA,0xA33,0xA3A,0xEE7,0x07B) {
	    push(@t, ($ef_vals[($t>>0) & 15]<<20) + ($ef_vals[($t>>4) & 15]<<10) + $ef_vals[($t>>8) & 15]);
	    
    }
    return @t;
    
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

# calcul d'une palette de 16 couleurs
sub find_palette {
	my($max, @px) = @_;

	# cas TO7
	return &to770_palette if $glb_to7pal;
    
	# si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
	# directement
	my($i, %pal);
	foreach $i (@px) {
		$pal{&ef_clamp($i)} = 1;
		last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	return @t if $#t<$max;
	#return &to9_palette_simple($max, @px);
	return &to9_palette($max, @px);
}

sub ef_clamp {
	my($t) = @_;
	my($b) = $map_ef[$t & 255]; $t>>=10;
	my($g) = $map_ef[$t & 255]; $t>>=10;
	my($r) = $map_ef[$t & 255];
	$t = ((($r<<10)+$g)<<10)+$b;
	#print &irgb2hex($_[0]), "=>",&irgb2hex($t),"\n";
	return $t;
}

sub to9_palette_simple {
	my($max, @px) = @_;
	my($i, $t, @t);
	for($i=0; $i<8; ++$i) {
		$t = 0; 
		$t |= ($i&1)?255:0; $t<<=10;
		$t |= ($i&2)?255:0; $t<<=10;
		$t |= ($i&4)?255:0;
		push(@t, $t);
	}
	for($i=1; $i<8; ++$i) {
		$t = 0; 
		$t |= ($i&1)?$map_ef[128]:0; $t<<=10;
		$t |= ($i&2)?$map_ef[128]:0; $t<<=10;
		$t |= ($i&4)?$map_ef[128]:0;
		push(@t, $t);
	}
	push(@t, $map_ef[1]*((1<<20) + (1<<10) + 1));
	return @t;
}

sub to9_palette {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(0, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	foreach $c (@p) {delete $pal{$c} if $pal{$c}<4;}
	@p = (sort { $pal{$b} - $pal{$a} } keys %pal);
	print 1+$#p, " significant\n";
	
	my(@t);
	
	# on choisi les coins
	my(%p) = (%pal);
	my(@s);
	foreach $i (0, 1, 2, 3, 4, 5, 6, 7) 
	{push(@s, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00));}
	#foreach $i (1, 2, 4) 
	#{push(@s, ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00));}
	foreach $r (@s) {	
		my($d, $p) = (1e30, -1);
		foreach $c (keys %p) {
			#next if $p{$c} < 48 && (($c>>20) > $ef_vals[1] || (($c>>10)&255) > $ef_vals[1] || ($c&255) > $ef_vals[1]);
			my($z) = &irgb_dist_spec($c, $r);
			if($z < $d || $z==$d && $pal{$c}>$pal{$p}) {$d = $z; $p = $c;}
		}
		# si plus proche d'un autre coin (sauf 0), on laisse tomber
		foreach $j (@s) {
			next if $j==0 || $j == $r;
			if(&irgb_dist_spec($j, $p) <= $d) {$p=-1; last;}
		}
		if($p>=0) {
			delete $p{$p};
			push(@t, $p);
			print &irgb2hex($r), " = ", sprintf("%6d        %s", $pal{$p}, &irgb2hex($p)), "\n"; 
			$pal{$p} = 4000;
		}
	}
	@p = (sort { $pal{$b} - $pal{$a} } keys %pal);
	
	
	# normalisation
	my($w, $h) = (320, 200);
	my($size, $tot) = $w*$h;
	foreach $c (@p) {$tot += $pal{$c};}
	foreach $c (@p) {$pal{$c} = int(($pal{$c}*$size)/$tot);}
	
	# on construit une image fictive 1024*1024
	@p = ();
	for $c (sort keys %pal) {for($i = $pal{$c}; --$i>=0;) {push(@p, $c>>20, ($c>>10)&255, $c&255);}}
	while(1+$#p!=$size*3) {push(@p, 0,0,0);}
	
	unlink(".toto2.pnm");
	open(OUT,">.toto2.pnm"); print OUT "P6\n$w $h\n255\n", pack('C*', @p), "\n"; close(OUT);	
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm"); 
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/toto3_.png");
		
	# on reduit jusqu'à $max colors
	my($ncol) = 18;
	do {
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		$g = 0.6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>$h, normalize=>"True");
		$glb_magick->Gamma($glb_gamma);
		$glb_magick->Write("rgb/toto3__.png");
		
		%pal = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$t  = $map_ef[int($p[$i+2]*255)];
			$t |= $map_ef[int($p[$i+1]*255)]<<10;
			$t |= $map_ef[int($p[$i+0]*255)]<<20;
			++$pal{$t};
		}
		@c = (keys %pal);
		$ncol = int($ncol / 1.03);
	} while($ncol > $max);
	print "reduced down to ", 1+$#c, "\n";
		
	# tri par fréquence
	@t = (sort { $pal{$b} - $pal{$a} } keys %pal);		
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d", $pal{$t}, $r, $g, $b), "\n"; 
		}
	}
	
	return @t;
}

sub to9_palette_x {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(1, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	foreach $c (@p) {delete $pal{$c} if $pal{$c}<4;}
	@p = (sort { $pal{$b} - $pal{$a} } keys %pal);
	print 1+$#p, " significant\n";
	
	my(@t);
	
	if(0) {
		$i = &find_darkest(\@p);
		push(@t, splice(@p, $i, 1, ())) if $i>=1;
		push(@t, shift(@p));
	} else {
		# on choisi les coins
		my(%p) = (%pal);
		my(@s);
		foreach $i (0, 1, 2, 3, 4, 5, 6, 7) 
		{push(@s, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00));}
		#foreach $i (1, 2, 4) 
		#{push(@s, ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00));}
		foreach $r (@s) {	
			my($d, $p) = (1e30, -1);
			foreach $c (keys %p) {
				#next if $p{$c} < 48 && (($c>>20) > $ef_vals[1] || (($c>>10)&255) > $ef_vals[1] || ($c&255) > $ef_vals[1]);
				my($z) = &irgb_dist_spec($c, $r);
				if($z < $d || $z==$d && $pal{$c}>$pal{$p}) {$d = $z; $p = $c;}
			}
			# si plus proche d'un autre coin (sauf 0), on laisse tomber
			foreach $j (@s) {
				next if $j==0 || $j == $r;
				if(&irgb_dist_spec($j, $p) <= $d) {$p=-1; last;}
			}
			if($p>=0) {
				delete $p{$p};
				push(@t, $p);
				print &irgb2hex($r), " = ", sprintf("%6d        %s", $pal{$p}, &irgb2hex($p)), "\n"; 
			}
		}
		
		# on vire les couleurs sous-représentées
		foreach $c (keys %p) {delete $p{$c} if $p{$c}<64;}
		
		@p = (sort { $pal{$b} - $pal{$a} } keys %p);
	}
	
	while($#t < $max && $#p>=0) {
		if(
		$#t<7*1 + 0*8 + 0*10 || ($#t & 1)
		) {
			#print "\n\n\n$#t, plus loin\n";
			$i = &find_furthest(\@t, \@p);
			push(@t, splice(@p, $i, 1, ()));
		} else {
			#print "\n\n\n$#t, plus freq";
			# on prends la plus frequente
			push(@t, shift(@p));
		}
	}
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d %s", $pal{$t}, $r, $g, $b, $p{$t}?"*":""), "\n"; 
		}
	}
	
	return @t;
}

sub to9_palette_ouais {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(1, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	# on vire les couleurs sous-représentées
	foreach $c (@p) {
		#$t = 1;
		#$t *= 2 if (($c>>00) & 255)>$ef_vals[1];
		#$t *= 2 if (($c>>10) & 255)>$ef_vals[1];
		#$t *= 2 if (($c>>20) & 255)>$ef_vals[1];
		$t = 16;
		$t = 4 if (($c>>00) & 255)<=$ef_vals[1] || (($c>>00) & 255)>=$ef_vals[15];
		$t = 4 if (($c>>10) & 255)<=$ef_vals[1] || (($c>>10) & 255)>=$ef_vals[15];
		$t = 4 if (($c>>20) & 255)<=$ef_vals[1] || (($c>>20) & 255)>=$ef_vals[15];
		delete $pal{$c} if $pal{$c}<$t;}
	@p = (sort { $pal{$b} - $pal{$a} } keys %pal);
	print 1+$#p, " significant\n";
	
	my(@t);
	
	if(0) {
		$i = &find_darkest(\@p);
		push(@t, splice(@p, $i, 1, ())) if $i>=1;
		push(@t, shift(@p));
	} else {
		# on choisi les coins
		my(%p) = (%pal);
		my(@s);
		foreach $i (0, 1, 2, 3, 4, 5, 6, 7) 
		{push(@s, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00));}
		#foreach $i (1, 2, 4) 
		#{push(@s, ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00));}
		foreach $r (@s) {	
			my($d, $p) = (1e30, -1);
			foreach $c (keys %p) {
				#next if $p{$c} < 48 && (($c>>20) > $ef_vals[1] || (($c>>10)&255) > $ef_vals[1] || ($c&255) > $ef_vals[1]);
				my($z) = &irgb_dist_spec($c, $r);
				if($z < $d || $z==$d && $pal{$c}>$pal{$p}) {$d = $z; $p = $c;}
			}
			# si plus proche d'un autre coin (sauf 0), on laisse tomber
			foreach $j (@s) {
				next if $j==0 || $j == $r;
				if(&irgb_dist_spec($j, $p) <= $d) {$p=-1; last;}
			}
			if($p>=0) {
				delete $p{$p};
				push(@t, $p);
				print &irgb2hex($r), " = ", sprintf("%6d        %s", $pal{$p}, &irgb2hex($p)), "\n"; 
			}
		}
		
		@p = (sort { $pal{$b} - $pal{$a} } keys %p);
	}
	
	while($#t < $max && $#p>=0) {
		if(
		$#t<7*1 + 0*8 + 0*10 || ($#t & 1)
		) {
			#print "\n\n\n$#t, plus loin\n";
			$i = &find_furthest(\@t, \@p);
			push(@t, splice(@p, $i, 1, ()));
		} else {
			#print "\n\n\n$#t, plus freq";
			# on prends la plus frequente
			push(@t, shift(@p));
		}
	}
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d %s", $pal{$t}, $r, $g, $b, $p{$t}?"*":""), "\n"; 
		}
	}
	
	return @t;
}

sub to9_palette_XXX {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(1, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	# on vire les couleurs sous-représentées
	foreach $c (@p) {delete $pal{$c} if $pal{$c}<8;}
	@p = (keys %pal);
	print 1+$#p, " significant\n";
	
	# selectionne celle proche des coins
	my(%p) = (%pal);
	my(@s);
	foreach $i (0, 1, 2, 3, 4, 5, 6) 
	{push(@s, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00));}
	foreach $i (1, 2, 4) 
	{push(@s, ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00));}
	@p = ();
	foreach $r (@s) {
		my($d, $p) = (1e30, -1);
		foreach $c (keys %p) {
			next if $p{$c} < 48 && (($c>>20) > $ef_vals[1] || (($c>>10)&255) > $ef_vals[1] || ($c&255) > $ef_vals[1]);
			my($z) = &irgb_dist_spec($c, $r);
			if($z < $d || $z==$d && $pal{$c}>$pal{$p}) {$d = $z; $p = $c;}
		}
		# si plus proche d'un autre coin (sauf 0), on laisse tomber
		foreach $j (@s) {
			next if $j==0 || $j == $r;
			if(&irgb_dist_spec($j, $p) <= $d) {$p=-1; last;}
		}
		if($p>=0) {
			delete $p{$p};
			push(@p, $p);
			print &irgb2hex($r), " = ", sprintf("%6d        %s", $pal{$p}, &irgb2hex($p)), "\n"; 
		}
	}

	# on prend la couleur la plus frequente, puis la plus loin de celle là jusqu'à 10 couls ensuite une fois sur 2 on prend la plus nombreuse	
	my(@cpt) = (keys %pal);
	while($#p < $max && $#cpt>=0) {
		$i = &find_furthest(\@p, \@cpt);
		print &irgb2hex($cpt[$i]), " = ", sprintf("%6d        %s", $pal{$cpt[$i]}, &irgb2hex($cpt[$i])), "\n"; 
		push(@p, splice(@cpt, $i, 1, ()));
	}
	
	# on boost les plus diverses
	%p = ();
	foreach $c (@p) {$p{$c} = 1; $pal{$c} *= 800; $pal{$c} = 8000 if $pal{$c}>8000;}
	@p = (keys %pal);
	
	# normalisation
	my($w, $h) = (320, 200);
	my($size, $tot) = $w*$h;
	foreach $c (@p) {$tot += $pal{$c};}
	foreach $c (@p) {$pal{$c} = int(($pal{$c}*$size)/$tot);}
	
	# on construit une image fictive 1024*1024
	@p = ();
	for $c (sort keys %pal) {for($i = $pal{$c}; --$i>=0;) {push(@p, $c>>20, ($c>>10)&255, $c&255);}}
	while(1+$#p!=$size*3) {push(@p, 0,0,0);}
	
	unlink(".toto2.pnm");
	open(OUT,">.toto2.pnm"); print OUT "P6\n$w $h\n255\n", pack('C*', @p), "\n"; close(OUT);	
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm"); 
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/toto3_.png");
		
	# on reduit jusqu'à $max colors
	@cpt = (keys %pal);
	my($ncol) = 18;
	do {
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		$g = 0.6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>$h, normalize=>"True");
		$glb_magick->Gamma($glb_gamma);
		$glb_magick->Write("rgb/toto3__.png");
		
		%pal = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$t  = $map_ef[int($p[$i+2]*255)];
			$t |= $map_ef[int($p[$i+1]*255)]<<10;
			$t |= $map_ef[int($p[$i+0]*255)]<<20;
			++$pal{$t};
		}
		@c = (keys %pal);
		print 1+$#c, "\n";
		$ncol = int($ncol / 1.03);
	} while(1+$#c > $max);
	print "reduced down to ", 1+$#c, "\n";
	
	while($#c < $max && $#cpt>=0) {
		$i = &find_furthest(\@c, \@cpt);
		push(@c, splice(@cpt, $i, 1, ()));
	}
		
	# tri par fréquence
	@t = (sort { $pal{$b} - $pal{$a} } @c);		
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d %s", $pal{$t}, $r, $g, $b, $p{$t}?"*":""), "\n"; 
		}
	}
	
	return @t;
}

sub to9_palette_diversity {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(1, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	# on vire les couleurs sous-représentées
	foreach $c (@p) {delete $pal{$c} if $pal{$c}<8;}
	@p = (keys %pal);
	print 1+$#p, " significant\n";
	
	# selectionne celle proche des coins
	my(%p) = (%pal);
	@p = ();
	my(@s);
	foreach $i (0, 1, 2, 3, 4, 5, 6, 7) 
	{push(@s, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00));}
	#foreach $i (@s) {$i = ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00);}
	foreach $i (1, 2, 4, 7) 
	{push(@s, ((($i&1)?$ef_vals[1]:0)<<20) + ((($i&2)?$ef_vals[1]:0)<<10) + ((($i&4)?$ef_vals[1]:0)<<00));}
	#push(@s, $ef_vals[1]<<20, $ef_vals[1]<<10, $ef_vals[1]);
	foreach $r (@s) {
		my($d, $p) = (1e30, -1);
		foreach $c (keys %p) {
			next if $p{$c} < 32*3 && (($c>>20) > $ef_vals[1] || (($c>>10)&255) > $ef_vals[1] || ($c&255) > $ef_vals[1]);
			my($z) = &irgb_dist_spec($c, $r);
			if($z < $d || $z==$d && $pal{$c}>$pal{$p}) {$d = $z; $p = $c;}
		}
		# si plus proche d'un autre coin (sauf 0), on laisse tomber
		foreach $j (@s) {
			next if $j==0 || $j == $r;
			if(&irgb_dist_spec($j, $p) <= $d) {$p=-1; last;}
		}
		if($p>=0) {
			delete $p{$p};
			push(@p, $p);
			print &irgb2hex($r), " = ", sprintf("%6d        %s", $pal{$p}, &irgb2hex($p)), "\n"; 
		}
	}

	# on prend la couleur la plus frequente, puis la plus loin de celle là jusqu'à 10 couls ensuite une fois sur 2 on prend la plus nombreuse	
	my(@cpt) = (keys %pal);
	while($#p < $max && $#cpt>=0) {
		$i = &find_furthest(\@p, \@cpt);
		push(@p, splice(@cpt, $i, 1, ()));
	}
	
	# tri par fréquence
	@p = (sort { $pal{$b} - $pal{$a} } @p);		
	
	# on complète avec des zero
	@p = (@p, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@p) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d", $pal{$t}, $r, $g, $b), "\n"; 
		}
	}
	
	return @p;
}

sub to9_paletteS12 {
	my($max, @px) = @_;

	# on dither au niveau thomson
	my(@p) = &simple_dither(1, @px); 
	my($i, $c, $t, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {++$pal{($p[$i+0]<<20) + ($p[$i+1]<<10) + $p[$i+2]};}
	@p = (keys %pal);
	print 1+$#p, " colors\n";
	
	# on vire les couleurs sous-représentées
	foreach $c (@p) {delete $pal{$c} if $pal{$c}<8;}
	@p = (keys %pal);
	print 1+$#p, " significant\n";
	
	# on boost les couleurs proches des coins
	for($i = 0; $i<8; ++$i) {
		my($r) = ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + ((($i&4)?255:0)<<00);
		my($d, $p) = (1e30, -1);
		foreach $c (@p) {
			my($z) = &irgb_dist_spec($c, $r);
			if($z < $d) {$d = $z; $p = $c;}
		}
		# si plus proche d'un autre coin (sauf 0), on laisse tomber
		for(my $j = 1; $j<8; ++$j) {
			next if $i == $j;
			my($r) = ((($j&1)?255:0)<<20) + ((($j&2)?255:0)<<10) + ((($j&4)?255:0)<<00);
			if(&irgb_dist_spec($r, $p) <= $d) {$p=-1; last;}
		}
		if($p>=0) {
			print &irgb2hex($r), " => ", &irgb2hex($p), " (",$pal{$p},")\n";
			$pal{$p} = 8000;
		}
	}
	
	# normalisation
	my($w, $h) = (320, 200);
	my($size, $tot) = $w*$h;
	foreach $c (@p) {$tot += $pal{$c};}
	foreach $c (@p) {$pal{$c} = int(($pal{$c}*$size)/$tot);}
	
	# on construit une image fictive 1024*1024
	@p = ();
	for $c (sort keys %pal) {for($i = $pal{$c}; --$i>=0;) {push(@p, $c>>20, ($c>>10)&255, $c&255);}}
	while(1+$#p!=$size*3) {push(@p, 0,0,0);}
	
	unlink(".toto2.pnm");
	open(OUT,">.toto2.pnm"); print OUT "P6\n$w $h\n255\n", pack('C*', @p), "\n"; close(OUT);	
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm"); 
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/toto3_.png");
		
	# on reduit jusqu'à $max colors
	my($ncol) = 18;
	do {
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		$g = 0.6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>$h, normalize=>"True");
		$glb_magick->Gamma($glb_gamma);
		$glb_magick->Write("rgb/toto3__.png");
		
		%pal = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$t  = $map_ef[int($p[$i+2]*255)];
			$t |= $map_ef[int($p[$i+1]*255)]<<10;
			$t |= $map_ef[int($p[$i+0]*255)]<<20;
			++$pal{$t};
		}
		@c = (keys %pal);
		$ncol = int($ncol / 1.03);
	} while($ncol > $max);
	print "reduced down to ", 1+$#c, "\n";
		
	# tri par fréquence
	@t = (sort { $pal{$b} - $pal{$a} } keys %pal);		
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d", $pal{$t}, $r, $g, $b), "\n"; 
		}
	}
	
	return @t;
}

sub irgb_dist_spec {
	my($rgb1, $rgb2) = @_;
	my($d, $t) = 0;
	$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $t = abs($t); $d += $t; $rgb1>>=10; $rgb2>>=10;
	$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $t = abs($t); $d += $t; $rgb1>>=10; $rgb2>>=10;
	$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $t = abs($t); $d += $t; $rgb1>>=10; $rgb2>>=10;
	return $d;
}


sub to9_palettexxxxxXXXXXX {
	my($max, @px) = @_;

	# on trouve les couleurs pures 1er ordre et 2eme ordre
	my($t, @p); #for $t (@px) {push(@p, $map_ef[$t>>20], $map_ef[($t>>10)&255], $map_ef[$t & 255]);}
	my @pp = simple_dither(1, @px);
	unlink(".toto2.pnm");
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @pp), "\n"; close(OUT);	
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm"); 
	#$glb_magick->ContrastStretch("0");
	$glb_magick->Quantize(colors=>200*0+0*48+64*0+512, colorspace=>"RGB", treedepth=>0, dither=>"True");
	my(@p) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/toto3_.png");
	
	my($i, %pal);
	for($i=$#p+1; ($i-=3)>=0;) {
		$t  = $map_ef[int($p[$i+2]*255)];
		$t |= $map_ef[int($p[$i+1]*255)]<<10;
		$t |= $map_ef[int($p[$i+0]*255)]<<20;
		++$pal{$t};
	}
	
	my(@m, @d, @c);
	for($i = 0; $i<8; ++$i) {push(@m, -1); push(@d, 1e30); push(@c, ((($i&1)?255:0)<<20) + ((($i&2)?255:0)<<10) + (($i&4)?255:0));}
	
	foreach $t (keys %pal) {
		#print &irgb2hex($t),"\n";
		next if $pal{$t}<8;
		#next unless $t;
		for($i = 0; $i<=$#c; ++$i) {
			#my($z);
			#$z = ($t>>00) & 255; next if (($c[$i]>>00) & 255) ? $z<80 : $z>50;
			#$z = ($t>>10) & 255; next if (($c[$i]>>10) & 255) ? $z<80 : $z>50;
			#$z = ($t>>20) & 255; next if (($c[$i]>>20) & 255) ? $z<80 : $z>50;
			#my($b) = ($t>>00) & 255;
			#my($g) = ($t>>10) & 255;
			#my($r) = ($t>>20) & 255;
			#my($z) = $b; $z = $g if $g>$z; $z = $r if $r>$z;
			#my($min) = $z*.3;
			#my($max) = $z*.5;
			#next if $b>$min && $b<$max;
			#next if $g>$min && $g<$max;
			#next if $r>$min && $r<$max;
			#my($s) = (($b>=$max)?255:0) + ((($g>=$max)?255:0)<<10) + ((($r>=$max)?255:0)<<20);
			#next if $s!=$c[$i];
			
			#ext if ($t & $c[$i])!=$t;
			#print &irgb2hex($t),"\n";
			my($d) = &irgb_dist($c[$i], $t);
			next if $d > &irgb_dist($ef_vals[0],$ef_vals[1])*2
				&& irgb_dist($t & ~$c[$i], 0)>irgb_dist($ef_vals[0],$ef_vals[1])
				#&& !(($c[$i] & $t)==$t && ($t & ~$c[$i])==0)
				&& 1;
			if($d < $d[$i]) {$d[$i] = $d; $m[$i] = $t;}
		}
	}
	# on retire celles qui sont plus proches que d'autres
	for($i = 0; $i<=$#c; ++$i) {
		next if $m[$i]<0;
		$d = &irgb_dist($m[$i], $c[$i])*.5;
		my($j);
		for($j = 0; $j<=$#c; ++$j) {
			next if $i == $j;
			if(&irgb_dist($m[$i], $c[$j]) <= $d) {$m[$i] = -1; last;}
		}
	}
	my(%p) = (); for($i=0; $i<=$#m; ++$i) {next if $m[$i]<0; $p{$m[$i]} = $pal{$m[$i]}; print &irgb2hex($c[$i]), " => ", &irgb2hex($m[$i]), " (",$pal{$m[$i]}, ")\n";}
	
	# on multiplie la frequence des primaires
	my($weight) = 40;
	@p = ();
	#for $t (@px) {push(@p, $t>>20, ($t>>10)&255, $t & 255);}
	push(@p, @pp);
	foreach $t (keys %p) {$i = $p{$t}*$weight; $i = 4000 if $i>$4000; while(--$i>=0) {push(@p, $t>>20, ($t>>10)&255, $t&255);}}
	
	# on forme une image rectangulaire
	my($height) = int(($#p + 3*320)/(3*320));
	print "height=$height\n";
	while(1+$#p < $height*3*320) {push(@p, 0,0,0);}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 $height\n255\n", pack('C*', @p), "\n"; close(OUT);	
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/toto2__.png");
	$glb_magick->Gamma(1/$glb_gamma);
		
	# on dither jusqu'à $max colors
	my($ncol) = $max;
	do {
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		$g = 0.6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>$height, normalize=>"True");
		$glb_magick->Gamma(gamma=>$glb_gamma);
		$glb_magick->Write("rgb/toto2_.png");
		%p = %pal;
		%pal = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$t  = $map_ef[int($p[$i+2]*255)];
			$t |= $map_ef[int($p[$i+1]*255)]<<10;
			$t |= $map_ef[int($p[$i+0]*255)]<<20;
			++$pal{$t	};
		}
		@c = (keys %pal);
		$ncol = 1+int($ncol * 1.03);
	} while($ncol < 512 && $#c < $max);
	@c = (keys %p);
	print "reduced down to ", 1+$#c, " ($ncol)\n";
		
	# tri par fréquence
	@t = (sort { $p{$b} - $p{$a} } keys %p);		
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	my($dbg) = 1;
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", sprintf("%6d        %3d, %3d, %3d", $p{$t}, $r, $g, $b), "\n"; 
		}
	}
	
	return @t;
}

sub to9_palette_presque_super {
	my($max, @px) = @_;
	
	# on dither jusqu'à $max colors
	my($ncol) = $max;
	my(@p, $t); for $t (@px) {push(@p, $t>>20, ($t>>10)&255, $t & 255);}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @p), "\n"; close(OUT);	
	do {
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		$g = .6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
		$glb_magick->Gamma(gamma=>$glb_gamma);
		$glb_magick->Write("rgb/toto2_.png");
		%pal = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$b = $map_ef[int($p[$i+2]*255) & 255];
			$g = $map_ef[int($p[$i+1]*255) & 255];
			$r = $map_ef[int($p[$i+0]*255) & 255]; 
			++$pal{((($r<<10) + $g)<<10) + $b};
		}
		@t = (keys %pal);	
		$ncol = 1+int($ncol * 1.03);
	} while($ncol < 512 && $#t+1 < $max);
	print "reduced down to $ncol\n";
	
	# on trouve les max par composantes
	my(@m) = (0)x7;
	my(@d) = (1e30)x7;
	my(@c); for($r = 1; $r<8; ++$r) {push(@c, ((($r&1)?255:0)<<20) + ((($r&2)?255:0)<<10) + (($r&4)?255:0));}
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	$glb_magick->Quantize(colors=>128, colorspace=>"RGB", treedepth=>0, dither=>"False");
	@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	my(%pal2);
	for($i=$#p+1; ($i-=3)>=0;) {
		$b = $map_ef[int($p[$i+2]*255) & 255];
		$g = $map_ef[int($p[$i+1]*255) & 255];
		$r = $map_ef[int($p[$i+0]*255) & 255]; 
		++$pal2{((($r<<10) + $g)<<10) + $b};
	}
	foreach $r (keys %pal2) {
		$t = ((($map_ef[$r>>20]<<10) + $map_ef[($r>>10)&255])<<10) + $map_ef[$r & 255];
		print &irgb2hex($t), "\n";
		for($i = 0; $i<8; ++$i) {next if ($t & $c[$i])!=$t; $g = &irgb_dist($c[$i], $t); if($g < $d[$i]) {$d[$i] = $g; $m[$i] = $t;}}
	}
	for($i=0; $i<=$#m; ++$i) {$t = $m[$i]; $pal{$t} = 1; print &irgb2hex($c[$i]),"==>",&irgb2hex($t),"\n";}
	
	# on dither
	#@$glb_magick = ();
	#$glb_magick->Read(".toto2.pnm");
	#@p = (); for $t (keys %pal) {push(@p, $t>>20, ($t>>10)&255, $t & 255);}
	#open(OUT,">.toto2.pnm"); print OUT "P6\n",(1+$#p)/3," A\n255\n", pack('C*', @p), "\n"; close(OUT);	
	#my($img) = Image::Magick->new;
	#$img->Read(".toto2.pnm");
	#$glb_magick->Map(image=>$img, "dither-method"=>"Riemersma");
	#undef $img;
	unlink ".toto2.pnm";
	
	# on récupère les couleurs utilisées
	#@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	#$glb_magick->Write("rgb/toto2_.png");
	#%pal = ();
	#for($i=$#p+1; ($i-=3)>=0;) {
	#	$b = $map_ef[int($p[$i+2]*255) & 255];
	#	$g = $map_ef[int($p[$i+1]*255) & 255];
	#	$r = $map_ef[int($p[$i+0]*255) & 255]; 
	#	++$pal{((($r<<10) + $g)<<10) + $b};
	#}
	
	@t = (keys %pal); %pal = ();
	for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	
	# tri par fréquence
	my(@cpt) = (sort { $pal{$b} - $pal{$a} } keys %pal);		
	print "really used: ", 1+$#cpt, "\n";
	
	# on reconstruit la palette en fonction des distances
	# on coupe les couls sous-représentées
	my($thr) = 32;
	@t = @cpt; @cpt = ();
	for $t (@t) {push(@cpt, $t) if $pal{$t} >= $thr;}
	print "really significant: ", 1+$#cpt, "\n";
	
	# on prend la couleur la plus frequente, puis la plus loin de celle là jusqu'à 10 couls ensuite une fois sur 2 on prend la plus nombreuse
	@t = ();
	
	# la plus sombre
	$i = &find_darkest(\@cpt); push(@t, splice(@cpt, $i, 1, ())) if $i>=1;
	
	# la plus frequente
	push(@t, shift(@cpt));
	push(@t, shift(@cpt));
	push(@t, shift(@cpt));
	push(@t, shift(@cpt));
	
	while($#t < $max && $#cpt>=0) {
		$i = &find_furthest(\@t, \@cpt);
		push(@t, splice(@cpt, $i, 1, ()));
	}
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	$dbg = 1;
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

sub find_palette_pasmal {
	my($max, @px) = @_;

	# cas TO7
	return &to770_palette if $glb_to7pal;
    
	# si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
	# directement
	my($i, %pal);
	foreach $i (@px) {
		$pal{$i} = 1;
		last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	return @t if $#t<$max;
	
	# on trouve les niveaux max par composantes
	my($mr, $mg, $mb, $t, $r, $g) = #(0, 0, 0);
	(250,250,250);
	#foreach $i (@px) {
	#	$t = $i;
	#	$b = $map_ef[$t & 255]; $t >>= 10;
	#	$g = $map_ef[$t & 255]; $t >>= 10;
	#	$r = $map_ef[$t & 255];
	#	$mr = $r if $r>$mr;
	#	$mg = $g if $g>$mg;
	#	$mb = $b if $b>$mb;
	#}
	
	# on construit une palette avec peu de couleurs
	@t = ();
	for($i = 0; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $mr : 0; $t<<=10;
		$t += $i & 2 ? $mg : 0; $t<<=10;
		$t += $i & 4 ? $mb : 0;
		push(@t, $t);
	}
	my($hr, $hg, $hb) = 
		($map_ef[int($mr*.66)], $map_ef[int($mg*.66)], $map_ef[int($mb*.66)]);
		#($map_ef[int($mr*.8)], $map_ef[int($mg*.8)], $map_ef[int($mb*.8)]);
	for($i = 1; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $hr : 0; $t<<=10;
		$t += $i & 2 ? $hg : 0; $t<<=10;
		$t += $i & 4 ? $hb : 0;
		push(@t, $t);
	}
	
	# on réduit l'image pour récupérer les stats de frequence
	my($ncol, @cpt) = $max;
	my(@p) = ();
	for $t (@px) {push(@p, $t>>20, ($t>>10)&255, $t & 255);}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @p), "\n"; close(OUT);	
	do {
		#for $t (@px) {push(@p, &ammag($t>>20), &ammag(($t>>10)&255), &ammag($t & 255));}
		@$glb_magick = ();
		$glb_magick->Read(".toto2.pnm");
		#$glb_magick->Modulate('saturation'=>110);
		#$glb_magick->SigmoidalContrast("Contrast"=>4);
		#$glb_magick->ContrastStretch("0,0");
		$g = .6;
		$glb_magick->Gamma(gamma=>1.0/$g);
		$glb_magick->Quantize(colors=>$ncol, colorspace=>"RGB", treedepth=>0, dither=>"False");
		$glb_magick->Gamma(gamma=>$g);
		@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
		$glb_magick->Gamma(gamma=>$glb_gamma);
		$glb_magick->Write("rgb/toto2_.png");
		%pal2 = ();
		for($i=$#p+1; ($i-=3)>=0;) {
			$b = $map_ef[int($p[$i+2]*255) & 255];
			$g = $map_ef[int($p[$i+1]*255) & 255];
			$r = $map_ef[int($p[$i+0]*255) & 255]; 
			++$pal2{((($r<<10) + $g)<<10) + $b};
		}
		@cpt = (sort { $pal2{$b} - $pal2{$a} } keys %pal2);	
		$ncol = 1+int($ncol * 1.03);
	} while($ncol < 512 && $#cpt+1 < $max);
	unlink(".toto2.pnm") || die;
	print "ncol=$ncol\n";
	
	#%pal = ();
	#for $t (@t)   {$pal{$t} = 0;}
	#for $t (@cpt) {$pal{$t} = 0;}
	#@t = (keys %pal);
	#for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	#@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	#@t = (@t, (0) x $max)[0..($max-1)];
	#return @t;
	
	@t = ();
	while($#t+1<$max) {push(@t, shift(@cpt));}
	@t = (@t, (0) x $max)[0..($max-1)];
	#simple_dither_wpal(1, 1+$#t, @t, @px);
	return @t;
	
	# on fait des combinaisons pour complèter la palette
	#@p = &simple_dither_wpal(1, 1+$#t, @t, @px);
	#%pal = ();
	#for $t (@t) {$pal{$t} = 0;} 
	#for($i = 0; $i<$#p; $i+=2) {
	#	$t = &irgb_avg($p[$i], $p[$i+1]);
	#	$b = $map_ef[$t & 255]; $t >>= 10;
	#	$g = $map_ef[$t & 255]; $t >>= 10;
	#	$r = $map_ef[$t & 255];
	#	++$pal{($r<<20)+($g<<10)+$b};
	#}
	#for($i = 0; $i<8; ++$i) {
	#	$t  = 0;
	#	$t += $i & 1 ? $mr : 0; $t<<=10;
	#	$t += $i & 2 ? $mg : 0; $t<<=10;
	#	$t += $i & 4 ? $mb : 0;
	#	$pal{$t} = 1000000;
	#}
	#@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	#@t = (@t, (0) x 16)[0..15];
	
	# dither avec la nouvelle palette
	#%pal = ();
	#for $t (@cpt) {$pal{$t} = 0;} 
	#for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	#@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	#@t = (@t, (0) x $max)[0..($max-1)];
	
	# affichage des stats
	my($dbg) = 1;
	if($dbg) {
		for $t (@t) {
			print &irgb2hex($t), "  = ", $pal2{$t},"\n";
		}
		print "\n";
	}	
	
	# on remplace les sous-représentées par les plus fréquentes
	for($i=1; $i && 1+$#cpt;) {
		$i = 0;
		%pal = ();
		for $t (@t) {$pal{$t} = 0;} 
		for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
		
		for $t (@t) {
			if($pal{$t} == 0) {
				$i = 1;
				print &irgb2hex($t), " ($pal{$t}) remplace par ";
				$t = splice(@cpt, 0, 1, ());
				print &irgb2hex($t), " ($pal2{$t})\n";
			}
		}

		if(!$i) {
		for $t (@t) {
			if($pal{$t} <= 128 + 0*256 + 0*16*4 + 60*0 + 128*0 + 512*0) {
				$i = 1;
				print &irgb2hex($t), " ($pal{$t}) remplace par ";
				$t = splice(@cpt, 0, 1, ());
				print &irgb2hex($t), " ($pal2{$t})\n";
			}
		}
		}
		
		print "\n" if $i;
	}

	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", $pal{$t}, " ", $r,",",$g,",",$b," ",$t,"\n"; 
		}
	}
	
	#&simple_dither_wpal(1, 1+$#t, @t, @px);
	
	return @t;
}

sub find_palette_exp3 {
	my($max, @px) = @_;

	# cas TO7
	return &to770_palette if $glb_to7pal;
    
	# si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
	# directement
	my($i, %pal);
	foreach $i (@px) {
		$pal{$i} = 1;
		last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	return @t if $#t<$max;
	
	# on trouve les niveaux max par composantes
	my($mr, $mg, $mb, $t, $r, $g) = (0, 0, 0);
	foreach $i (@px) {
		$t = $i;
		$b = $map_ef[$t & 255]; $t >>= 10;
		$g = $map_ef[$t & 255]; $t >>= 10;
		$r = $map_ef[$t & 255];
		$mr = $r if $r>$mr;
		$mg = $g if $g>$mg;
		$mb = $b if $b>$mb;
	}
	
	# on construit une palette avec peu de couleurs
	@t = ();
	for($i = 0; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $mr : 0; $t<<=10;
		$t += $i & 2 ? $mg : 0; $t<<=10;
		$t += $i & 4 ? $mb : 0;
		push(@t, $t);
	}
	#my($hr, $hg, $hb) = ($map_ef[int($mr*.6)], $map_ef[int($mg*.6)], $map_ef[int($mb*.6)]);
	#for($i = 1; $i<8; ++$i) {
	#	$t  = 0;
	#	$t += $i & 1 ? $hr : 0; $t<<=10;
	#	$t += $i & 2 ? $hg : 0; $t<<=10;
	#	$t += $i & 4 ? $hb : 0;
	#	push(@t, $t);
	#}
	
	# on réduit l'image pour récupérer les stats de frequence
	my(@p) = ();
	for $t (@px) {push(@p, &ammag($t>>20), &ammag(($t>>10)&255), &ammag($t & 255));}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @p), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	$glb_magick->Write("rgb/toto2_.png");
	$glb_magick->Quantize(colors=>48, colorspace=>"RGB", treedepth=>0, dither=>"False");
	@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	%pal2 = ();
	for($i=$#p+1; ($i-=3)>=0;) {
		$t = &rgb2irgb(@p[$i..$i+2]); 
		$b = $map_ef[$t & 255]; $t >>= 10;
		$g = $map_ef[$t & 255]; $t >>= 10;
		$r = $map_ef[$t & 255]; 
		++$pal2{((($r<<10) + $g)<<10) + $b};
	}
	for $t (@t) {undef $pal2{$t};}
	my(@cpt) = (sort { $pal2{$b} - $pal2{$a} } keys %pal2);	
	
	push(@t, shift(@cpt));
	
	# on fait des combinaisons pour complèter la palette
	@p = &simple_dither_wpal(1, 1+$#t, @t, @px);
	%pal = ();
	for $t (@t) {$pal{$t} = 0;} 
	for($i = 0; $i<$#p; $i+=2) {
		$t = &irgb_avg($p[$i], $p[$i+1]);
		$b = $map_ef[$t & 255]; $t >>= 10;
		$g = $map_ef[$t & 255]; $t >>= 10;
		$r = $map_ef[$t & 255];
		++$pal{($r<<20)+($g<<10)+$b};
	}
	#for($i = 0; $i<8; ++$i) {
	#	$t  = 0;
	#	$t += $i & 1 ? $mr : 0; $t<<=10;
	#	$t += $i & 2 ? $mg : 0; $t<<=10;
	#	$t += $i & 4 ? $mb : 0;
	#	$pal{$t} = 1000000;
	#}
	@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	@t = (@t, (0) x 16)[0..15];
	
	# dither avec la nouvelle palette
	%pal = ();
	for $t (@cpt) {$pal{$t} = 0;} 
	for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	@t = (@t, (0) x $max)[0..($max-1)];
	
	# affichage des stats
	my($dbg) = 1;
	if($dbg) {
		for $t (@t) {
			print &irgb2hex($t), "  = ", $pal{$t},"\n";
		}
	}	
	
	# on remplace les sous-représentées par les plus fréquentes
	for($i=1; $i && 1+$#cpt;) {
		$i = 0;
		%pal = ();
		for $t (@cpt) {$pal{$t} = 0;} 
		for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
		
		for $t (@t) {
			if($pal{$t} <= 256 + 0*16*4 + 60*0 + 128*0 + 512*0) {
				$i = 1;
				print &irgb2hex($t), " ($pal{$t}) remplace par ";
				$t = splice(@cpt, 0, 1, ());
				print &irgb2hex($t), " ($pal2{$t})\n";
			}
		}
		
		print "\n" if $i;
	}

	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", $pal{$t}, " ", $r,",",$g,",",$b," ",$t,"\n"; 
		}
	}
	
	#&simple_dither_wpal(1, 1+$#t, @t, @px);
	
	return @t;
}

sub find_palette_exp2 {
	my($max, @px) = @_;

	# cas TO7
	return &to770_palette if $glb_to7pal;
    
	# si l'image a suffisament peu de couleurs alors on retourne la palette de l'image
	# directement
	my($i, %pal);
	foreach $i (@px) {
		$pal{$i} = 1;
		last if length(keys %pal)>$max;
	}
	my(@t) = keys(%pal);
	return @t if $#t<$max;
	
	# on trouve les niveaux max par composantes
	my($mr, $mg, $mb, $t, $r, $g) = (0, 0, 0);
	foreach $i (@px) {
		$t = $i;
		$b = $map_ef[$t & 255]; $t >>= 10;
		$g = $map_ef[$t & 255]; $t >>= 10;
		$r = $map_ef[$t & 255];
		$mr = $r if $r>$mr;
		$mg = $g if $g>$mg;
		$mb = $b if $b>$mb;
	}
	
	# on construit une palette avec peu de couleurs
	@t = ();
	for($i = 0; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $mr : 0; $t<<=10;
		$t += $i & 2 ? $mg : 0; $t<<=10;
		$t += $i & 4 ? $mb : 0;
		push(@t, $t);
	}
	my($hr, $hg, $hb) = ($map_ef[int($mr*.6)], $map_ef[int($mg*.6)], $map_ef[int($mb*.6)]);
	for($i = 0; $i<7; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $mr : $hr; $t<<=10;
		$t += $i & 2 ? $mg : $hg; $t<<=10;
		$t += $i & 4 ? $mb : $hb;
		push(@t, $t);
	}
	for($i = 1; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $hr : 0; $t<<=10;
		$t += $i & 2 ? $hg : 0; $t<<=10;
		$t += $i & 4 ? $hb : 0;
		push(@t, $t);
	}
	#for($i = 1; $i<8; ++$i) {
	#	$t  = 0;
	#	$t += $i & 1 ? $hr : $ef_vals[1]; $t<<=10;
	#	$t += $i & 2 ? $hg : $ef_vals[1]; $t<<=10;
	#	$t += $i & 4 ? $hb : $ef_vals[1];
	#	push(@t, $t);
	#}
	#for($i = 1; $i<8; ++$i) {
	#	$t  = 0;
	#	$t += $i & 1 ? $ef_vals[1] : 0; $t<<=10;
	#	$t += $i & 2 ? $ef_vals[1] : 0; $t<<=10;
	#	$t += $i & 4 ? $ef_vals[1] : 0;
	#	push(@t, $t);
	#}
	
	# on réduit l'image pour récupérer les stats de frequence
	my(@p) = ();
	for $t (@px) {push(@p, &ammag($t>>20), &ammag(($t>>10)&255), &ammag($t & 255));}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @p), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	$glb_magick->Write("rgb/toto2_.png");
	$glb_magick->Quantize(colors=>48, colorspace=>"RGB", treedepth=>0, dither=>"False");
	@p = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	%pal2 = ();
	for($i=$#p+1; ($i-=3)>=0;) {
		$t = &rgb2irgb(@p[$i..$i+2]); 
		$b = $map_ef[$t & 255]; $t >>= 10;
		$g = $map_ef[$t & 255]; $t >>= 10;
		$r = $map_ef[$t & 255]; 
		++$pal2{((($r<<10) + $g)<<10) + $b};
	}
	for $t (@t) {undef $pal2{$t};}
	my(@cpt) = (sort { $pal2{$b} - $pal2{$a} } keys %pal2);	
	
	while($#t+1<$max) {push(@t, shift(@cpt));}
	
	# dither + stats
	%pal = ();
	for $t (@t) {$pal{$t} = 0;} 
	for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	
	# affichage des stats
	my($dbg) = 1;
	if($dbg) {
		for $t (@t) {
			print &irgb2hex($t), "  = ", $pal{$t},"\n";
		}
	}
	
	# tri par fréquence et on retient les $max plus frequents
	@t = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	@t = (@t, (0) x $max)[0..($max-1)];
	if($dbg) {
		print "\n\n";
		for $t (@t) {
			print &irgb2hex($t), "  = ", $pal{$t},"\n";
		}
	}
	
	
	
	# on remplace les sous-représentées par les plus fréquentes
	for($i=1; $i && 1+$#cpt;) {
		$i = 0;
		%pal = ();
		for $t (@cpt) {$pal{$t} = 0;} 
		for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
		
		for $t (@t) {
			if($pal{$t} <= 256 + 0*16*4 + 60*0 + 128*0 + 512*0) {
				$i = 1;
				print &irgb2hex($t), " ($pal{$t}) remplace par ";
				$t = splice(@cpt, 0, 1, ());
				print &irgb2hex($t), " ($pal2{$t})\n";
			}
		}
		
		print "\n" if $i;
	}

	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", $pal{$t}, " ", $r,",",$g,",",$b," ",$t,"\n"; 
		}
	}
	
	#&simple_dither_wpal(1, 1+$#t, @t, @px);
	
	return @t;
}

sub find_palette_exp {
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
    
	#return &xxx_palette($max, @px) if $#map_ef>=0;
    
	# on remap l'image aux niveau produits par les puces thomson!
	if($#map_ef>=0) {
		@t = &simple_dither($use_dith, @px);
	}
	    
	# on réduit à 64 couls
	#$glb_magick->ContrastStretch("0");
	$glb_magick->Quantize(colors=>48, colorspace=>"RGB", treedepth=>0, dither=>"False");
	$glb_magick->Write("rgb/toto3.gif");
	@t = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	
	# on comptabilise les couleurs renormalisées au format Thomson
	%pal = ();
	my(%palR, %palV, %palB);
	$pal{0} = 1+$#t;
	for($i=$#t+1; ($i-=3)>=0;) {
		$rvb = &rgb2irgb(@t[$i..$i+2]);
		#$rvb = ((($map_ef2[$rvb>>20]<<10) + $map_ef2[($rvb>>10) & 0xff])<<10) + $map_ef2[$rvb & 0xff] if $#map_ef>=0;
		my($r, $v, $b) = ($map_ef[$rvb>>20], $map_ef[($rvb>>10) & 0xff], $map_ef[$rvb & 0xff]);
		$rvb = ((($r<<10) + $v)<<10) + $b if $#map_ef>=0;
		++$pal{$rvb & $mask};
		++$palR{$r};
		++$palV{$v};
		++$palB{$b};
	}
	
	# on trie par frequence
	my(@cpt) = (sort { $pal{$b} - $pal{$a} } keys %pal);	
	
	my(%pal2) = (%pal);
	
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
	my($thr) = 64;
	@t = @cpt; @cpt = ();
	for $t (@t) {
		push(@cpt, $t) if $pal{$t} >= $thr;
	}
		
	# on trouve le max r,v et b, et on forme 8 couleurs avec ca
	my($mr, $mg, $mb) = (0, 0, 0);
	for $i (@cpt) {
		$t = $i;
		$mr = $t & 255 if ($t & 255) > $mr; $t >>= 10;
		$mg = $t & 255 if ($t & 255) > $mg; $t >>= 10;
		$mb = $t & 255 if ($t & 255) > $mb; $t >>= 10;
	}
	
	my($mR, $mG, $mB) = ($map_ef[int($mr*.6)],$map_ef[int($mg*.6)],$map_ef[int($mb*.6)]);
	#($mr, $mg, $mb) = ($map_ef[int($mr*.9)],$map_ef[int($mg*.9)],$map_ef[int($mb*.9)]);
	my($zero) = 0; #$ef_vals[1];
	
	# on prend les plus frequences
	#$palR{0} = $palR{255} = $palR{$mr} = $palV{0} = $palV{255} = $palV{$mg} = $palB{0} = $palB{255} = $palB{$mb} = -1;
	#@t = (sort { $palR{$b} - $palR{$a} } keys %palR); $mR = $t[0];
	#@t = (sort { $palV{$b} - $palV{$a} } keys %palV); $mG = $t[0];
	#@t = (sort { $palB{$b} - $palB{$a} } keys %palB); $mB = $t[0];
	#print $mR/$mr, " ", $mG/$mg, " ", $mB/$mb, "\n";
	
	@t = (); %pal = ();
	for($i = 0; $i<8; ++$i) {
		$t  = 0;
		$t += $mr if $i & 1; $t<<=10;
		$t += $mg if $i & 2; $t<<=10;
		$t += $mb if $i & 4;
		push(@t, $t); $pal{$t} = 1;
	}
	for($i = 1; $i<8; ++$i) {
		$t  = 0;
		$t += $i & 1 ? $mR : $zero; $t<<=10;
		$t += $i & 2 ? $mG : $zero; $t<<=10;
		$t += $i & 4 ? $mB : $zero;
		push(@t, $t); $pal{$t} = 1;
	}
	
	# on retire de @cpt les couleurs déjà présentes dans @t (typiquement le 0)
	my(@v) = @cpt; @cpt = ();
	for $t (@v) {push(@cpt, $t) unless defined $pal{$t};}
	
	# on ajoute la couleur la plus représentée
	push(@t, splice(@cpt, 0, 1, ()));
	
	do {$again = 0;
	# on dither et on fait les stats
	%pal = ();
	for $t (@t) {$pal{$t} = 0;} 
	for $t (&simple_dither_wpal(1, 1+$#t, @t, @px)) {++$pal{$t};}
	if($dbg) {
		print "\n\n";
		for $t (@t) {
			print &irgb2hex($t), " = ", $pal{$t},"\n";
		}
	}
	
	# les sous-représentées sont remplacées par les plus fréquentes
	for $t (@t) {
		if($pal{$t} <= 256 + 0*16*4 + 60*0 + 128*0 + 512*0) {
			$again = 1;
			print &irgb2hex($t), " ($pal{$t}) remplace par ";
			$t = splice(@cpt, 0, 1, ());
			print &irgb2hex($t), " ($pal2{$t})\n";
			last unless @cpt && defined $pal2{$t};
		}
	}
	$again &= 1+$#cpt;
	print "XXX\n" if $again;
	} while($again);
	
	# on complète avec des zero
	@t = (@t, (0) x $max)[0..($max-1)];
	
	if($dbg) {
		print "\n\n";foreach $t (@t) {
			my($r) = &ammag(($t>>20) & 0x1ff);
			my($g) = &ammag(($t>>10) & 0x1ff);
			my($b) = &ammag(($t>>00) & 0x1ff);
			print &irgb2hex($t), " = ", $pal{$t}, " ", $r,",",$g,",",$b," ",$t,"\n"; 
		}
	}
	
	&simple_dither_wpal(1, 1+$#t, @t, @px);
	
	return @t;
}

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
	#for $t (@t) {
	#		print &irgb2hex($t), "  = ", $pal{$t},"\n";
	#}
	return @t if $#t<$max;
	%pal = ();
	
	# idee par groupe de $w pixels on sature les valeurs RGB avec
	# les min/max ontenus pour ce groupe. L'idee est de réduire
	# la disperssion des couleurs
	if(0) {
		my($w, @t) = 8;
		for $rgb (@px) {push(@t, &irgb2rgb($rgb));}
		for($i=0; $i<=$#t; $i+=3*$w) {
			my($r,$v,$b) = (1000000,1000000,10000000);
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
				$t[$j+0] = &xint(255*($t[$j+0] < (1-$t)*$r + $t*$R ? $r : $R));
				$t[$j+1] = &xint(255*($t[$j+1] < (1-$t)*$v + $t*$V ? $v : $V));
				$t[$j+2] = &xint(255*($t[$j+2] < (1-$t)*$b + $t*$B ? $b : $B));
			}
		}
		
		@px = ();
		for($i = 0; $i<$#t; $i += 3) {
			push(@px, ($t[$i]<<20) | ($t[$i+1]<<10) | $t[$i+2]);
		}
	}

	# sinon on quantifie l'image:
	my($use_dith) = 1;
    
	#return &xxx_palette($max, @px) if $#map_ef>=0;
    
	# on remap l'image aux niveau produits par les puces thomson!
	if($#map_ef>=0) {
		@t = simple_dither($use_dith, @px);
	}
	    
	# on réduit à 64 couls
	#$glb_magick->ContrastStretch("0");
	$glb_magick->Quantize(colors=>($alt?48:24)*0+64*1+128*0+256*0, colorspace=>"RGB", treedepth=>0, dither=>($use_dith && !$alt & 0?"True":"False"));
	$glb_magick->Write("rgb/toto3.gif");
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
		
	# on prend la couleur la plus frequente, puis la plus loin de celle là jusqu'à 10 couls ensuite une fois sur 2 on prend la plus nombreuse
	@t = ();
	
	$i = &find_darkest(\@cpt);
	push(@t, splice(@cpt, $i, 1, ())) if $i>=1;
	
	push(@t, shift(@cpt));
	
	while($#t < $max && $#cpt>=0) {
		#print "\n\n";
		#for $t (@t) {
		#	print &irgb2hex($t), "  = ", $pal{$t},"\n";
		#}
		if(
		#1
		#$#t & 1
		$#t<7*1 + 0*8 + 0*10 || ($#t & 1)
		) {
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
		my($xstart, $xstop, $xinc) = (319, -1, -1);
		
		($xstart, $xstop, $xinc) = (0, 320, 1) if $y & 1;
		
		for($x=$xstart, $p = $y*320 + $x; $x!=$xstop; $x+=$xinc, $p+=$xinc) {
			my($ref) = $px[$p];
			
			$rvb = &irgb_sat($ref);

			$r=$map_ef[$rvb>>20]; $v=$map_ef[($rvb>>10) & 0xff]; $b=$map_ef[$rvb & 0xff];
			@t[3*$p..3*$p+2] = ($r, $v, $b); #(&ammag($r), &ammag($v), &ammag($b));
			$px[$p] = ((($r<<10)+$v)<<10)+$b;
			#push(@t, $r=($rvb>>20), $v=(($rvb>>10) & 0xff), $b=($rvb & 0xff));
			if($use_dith) {
				$rvb = &irgb_sub($rvb, $px[$p]);
				
				if($y & 1) {
					$px[$p + 319] = &irgb_sprd($px[$p + 319], $rvb, $ref, \@glb_ostr0) if $y<199 && $x>0;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p + 001] = &irgb_sprd($px[$p + 001], $rvb, $ref, \@glb_ostr2) if           $x<319;
				} else {
					$px[$p + 321] = &irgb_sprd($px[$p + 321], $rvb, $ref, \@glb_ostr0) if $y<199 && $x<319;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p - 001] = &irgb_sprd($px[$p - 001], $rvb, $ref, \@glb_ostr2) if           $x>0;
				}
			}
		}
	}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	
	$glb_magick->Gamma($glb_gamma);
	$glb_magick->Write("rgb/totoZ_.png");
	
	return @t;
}

sub simple_dither_wpal {
	my($use_dith, $num, @px) = @_;
	
	my(@pal) = splice(@px, 0, $num, ());
	
	my($x, $y, $p, $rvb, $r, $d, $dm);
	my(@t);
	for($y=0, $p=0; $y<200; ++$y) {
		my($xstart, $xstop, $xinc) = (319, -1, -1);
		($xstart, $xstop, $xinc) = (0, 320, 1) if $y & 1;
		
		for($x=$xstart, $p = $y*320 + $x; $x!=$xstop; $x+=$xinc, $p+=$xinc) {
			my($ref) = $rvb = $px[$p] = &irgb_sat($px[$p]);
			
			$dm = 1e30; for $r (@pal) {$d = &irgb_dist($rvb, $r); if($d < $dm) {$dm = $d; $px[$p] = $r;}}

			$r=$map_ef[$px[$p]>>20]; $v=$map_ef[($px[$p]>>10) & 0xff]; $b=$map_ef[$px[$p] & 0xff];
			@t[3*$p..3*$p+2] = (&ammag($r), &ammag($v), &ammag($b));
			
			if($use_dith) {
				$rvb = &irgb_sub($rvb, $px[$p]);
				
				if($y & 1) {
					$px[$p + 319] = &irgb_sprd($px[$p + 319], $rvb, $ref, \@glb_ostr0) if $y<199 && $x>0;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p + 001] = &irgb_sprd($px[$p + 001], $rvb, $ref, \@glb_ostr2) if           $x<319;
				} else {
					$px[$p + 321] = &irgb_sprd($px[$p + 321], $rvb, $ref, \@glb_ostr0) if $y<199 && $x<319;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p - 001] = &irgb_sprd($px[$p - 001], $rvb, $ref, \@glb_ostr2) if           $x>0;
				}
			}
		}
	}

	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	
	$glb_magick->Write("rgb/toto5_.png");

	return @px;
}

# dithering simple sans contraintes de proximité
sub simple_dither_pal {
	my($use_dith, @px) = @_;
	
	my($x, $y, $p, $rvb, $r, $v, $b, $dm, @t, @u);
	
	for($y=0, $p=0; $y<200; ++$y) {
		my($xstart, $xstop, $xinc) = (319, -1, -1);
		($xstart, $xstop, $xinc) = (0, 320, 1) if $y & 1;
		
		for($x=$xstart, $p = $y*320 + $x; $x!=$xstop; $x+=$xinc, $p+=$xinc) {
			my($ref) = $rvb = $px[$p];
			
			for($dm=1e30, $r=0; $r<$glb_maxcol; ++$r) {
				$v = &irgb_dist($rvb, $glb_pal[$r]);
				if($v < $dm) {$dm = $v; $b = $r;}
			}
			$px[$p] = $glb_pal[$b];
			@t[3*$p..3*$p+2] = (&ammag(($px[$p]>>20) & 255), &ammag(($px[$p]>>10) & 255), &ammag($px[$p]&255));
			
			if($use_dith) {
				$rvb = &irgb_sub($rvb, $px[$p]);
				
				if($y & 1) {
					$px[$p + 319] = &irgb_sprd($px[$p + 319], $rvb, $ref, \@glb_ostr0) if $y<199 && $x>0;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p + 001] = &irgb_sprd($px[$p + 001], $rvb, $ref, \@glb_ostr2) if           $x<319;
				} else {
					$px[$p + 321] = &irgb_sprd($px[$p + 321], $rvb, $ref, \@glb_ostr0) if $y<199 && $x<319;
					$px[$p + 320] = &irgb_sprd($px[$p + 320], $rvb, $ref, \@glb_ostr1) if $y<199;
					$px[$p - 001] = &irgb_sprd($px[$p - 001], $rvb, $ref, \@glb_ostr2) if           $x>0;
				}
			}
		}
	}
	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @t), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	$glb_magick->Write("rgb/toto3_.png");

	open(OUT,">.toto2.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @u), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto2.pnm");
	unlink(".toto2.pnm");
	$glb_magick->Write("rgb/toto4_.png");
 }

sub irgb_sprd {
	my($px, $err, $ref, $coef) = @_;
	my($r, $map) = 0;
	
	$ref = &irgb_sat($ref);
	
	$map = $coef->[$glb_sprd_idx[$ref & 255]]; $ref >>= 10;
	$r = $map->[$err & 0x1ff]; $err >>= 10;
	
	$map = $coef->[$glb_sprd_idx[$ref & 255]]; $ref >>= 10;
	$r |= $map->[$err & 0x1ff]<<10; $err >>= 10;
	
	$map = $coef->[$glb_sprd_idx[$ref & 255]];
	$r |= $map->[$err]<<20;
	
	return &irgb_add($px, $r); # add ou uadd?
}

sub find_darkest {
	my ($cols) = @_;
	my ($d, $dm, $i, $im);
	for($i = $#{$cols}, $dm = 1e38, $im = 0; $i>=0; --$i) {
		$d = &irgb_module($cols->[$i]);
		if($d<$dm) {$dm = $d; $im = $i;}
	}
	return $im;
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
	foreach $col (@$set) {
		$d = &irgb_dist_spec($rgb, $col);
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
	#$glb_magick->AutoGamma();
	#$glb_magick->AutoLevel();
	
	$glb_magick->Enhance();
	$glb_magick->Normalize(); #
	#$glb_magick->LinearStretch('black-point'=>0, 'white-point'=>1);
	#$glb_magick->Contrast(sharpen=>"True");
	#$glb_magick->ContrastStretch("4%,96%");
#	$glb_magick->ContrastStretch("5%"); #faible, mais pas mal pour un standard
#	$glb_magick->ContrastStretch("10%");
#	$glb_magick->ContrastStretch("8%");
	#$glb_magick->ContrastStretch("0");
	
	#$glb_magick->Set(antialias=>"True");
	$glb_magick->SigmoidalContrast(contrast=>2);
	$glb_magick->Gamma(0.98);
	
	#$glb_magick->Quantize(colorspace=>'gray');
	
	#$glb_magick->Gamma(0.8); #TEST
	$glb_magick->ContrastStretch("2%,99%"); #2% pour skyrim
	#$glb_magick->ContrastStretch("4%,99%"); #2% pour skyrim
	#$glb_magick->ContrastStretch("5%");
	
	#$glb_magick->Gamma(0.8);
	my($blur) = 1.15;
	$glb_magick->AdaptiveResize(geometry=>"320x200", filter=>"lanczos", blur=>1);
	$glb_magick->Border(width=>"320",height=>"100",color=>"black");
	#  $glb_magick->Blur(1);
	#  $glb_magick->OilPaint(2);
	$glb_magick->Set(gravity=>"Center");
	#	$glb_magick->Crop(geometry=>"320x200!", gravity=>"center");
	$glb_magick->Crop(geometry=>"320x200!");
	$glb_magick->Set(page=>"320x200+0+0");
	$glb_magick->Resize(geometry=>"320x200!", filter=>"lanczos", blur=>$blur);
	#$glb_magick->ReduceNoise(radius=>0);
	#$glb_magick->Gamma(gamma=>0.8) if $glb_to7pal;
	#$glb_magick->Gamma(gamma=>0.45);
	#$glb_magick->AdaptiveSharpen(radius=>3);
	#$glb_magick->AdaptiveBlur(radius=>4);
	#$glb_magick->Contrast(sharpen=>"True");
	#$glb_magick->Evaluate(operator=>"Multiply", value=>"0.9");

	if(0) {
		# ouais.. a voir.. ca reste neutre 
		$glb_magick->ContrastStretch("0");
		$glb_magick->Contrast(sharpen=>"True");
	} elsif(0) {
		#$glb_magick->ContrastStretch("0");
		$n=2048;$m=256;
		$glb_magick->ContrastStretch($n.",".(320*200-$m));
		#$glb_magick->ContrastStretch("3%");
	}
	
	#$glb_magick->ContrastStretch("5%,97%");
	#$glb_magick->ContrastStretch("10%");
	#$glb_magick->ContrastStretch("7%,91%"); #BIEN

	#print "XXX\n";
	&auto_stretch if 0;
	
	#print "YYY\n";
	
	&teo_level unless $glb_to7pal;
	
	#$glb_magick->ContrastStretch("3%");

	
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
		$glb_magick->Write("rgb/.toto.png");
		unlink(".toto.pnm");
	}
	my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	my($i, @px);
	my(@u) = (@t);
	#for $i (@u) {$i = &ammag($map_ef[&gamma($i*255)])/255.0;}
	for($i = 0; $i<$#t; $i += 3) {
		push(@px, &rgb2irgb(($t[$i]*7 + $u[$i]*1)/8, ($t[$i+1]*7 + $u[$i+1]*1)/8, ($t[$i+2]*7 + $u[$i+2]*1)/8));
	}
	
	#$glb_magick->Write("rgb/totof.png");
	write_image("rgb/totof.png", @px);
	return @px;
}

sub teo_level {
	my($min, $max) = (64, 255);
	my(@ef) = @map_ef;
	my($i, $j, $m, @c);
	my($tr, $vr, $tg, $vg, $tb, $vb);

	my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	for $i (@t) {$i = &gamma($i*255);}
	
	my(@px);
	#for($i=0; $i<$#t; $i+=3) {push(@px, int($t[$i+0]), int($t[$i+1]), int($t[$i+2]));}
	#open(OUT,">.toto.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @px), "\n"; close(OUT);
	#@$glb_magick = ();
	#$glb_magick->Read(".toto.pnm");
	
	$glb_magick->Quantize(colors=>48*1+0*128, colorspace=>"RGB", treedepth=>0, dither=>"false");
	$glb_magick->Write("rgb/toto4.gif");	
	my(@p) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	for $i (@p) {$i = &gamma($i*255);}

	@c = (0) x 256; for($i = 0; $i<$#p; $i+=3) {++$c[int(0.5+$p[$i])];}
	$j=$min; $m = $ef[$j]>0 ? $c[$j] : 0; for($i=$j+1; $i<=$max; ++$i) {if($c[$i] >= $m && $ef[$i]>0 && $ef[$i]<255) {$m=$c[$j=$i];}}
	$tr = $ef[$j]; $vr = $j; #print "$tr $vr $m\n";
	
	@c = (0) x 256; for($i = 1; $i<$#p; $i+=3) {++$c[int(0.5+$p[$i])];}
	$j=$min; $m = $ef[$j]>0 ? $c[$j] : 0; for($i=$j+1; $i<=$max; ++$i) {if($c[$i] >= $m && $ef[$i]>0 && $ef[$i]<255) {$m=$c[$j=$i];}}
	$tg = $ef[$j]; $vg = $j; #print "$tg $vg $m\n";
	
	@c = (0) x 256; for($i = 2; $i<$#p; $i+=3) {++$c[int(0.5+$p[$i])];}
	$j=$min; $m = $ef[$j]>0 ? $c[$j] : 0; for($i=$j+1; $i<=$max; ++$i) {if($c[$i] >= $m && $ef[$i]>0 && $ef[$i]<255) {$m=$c[$j=$i];}}
	$tb = $ef[$j]; $vb = $j; #print "$tb $vb $m\n";
	
	for($i=0; $i<$#t; $i+=3) {
		$t[$i+0] = &correct($t[$i+0], $tr, $vr);
		$t[$i+1] = &correct($t[$i+1], $tg, $vg);
		$t[$i+2] = &correct($t[$i+2], $tb, $vb);
	}
	for $i (@t) {$i=0 if $i<0; $i=255 if $i>255;}
	
	@px = (); for($i=0; $i<$#t; $i+=3) {push(@px, int(0.5+&ammag($t[$i+0])), int(0.5+&ammag($t[$i+1])), int(0.5+&ammag($t[$i+2])));}
	open(OUT,">.toto.pnm"); print OUT "P6\n320 200\n255\n", pack('C*', @px), "\n"; close(OUT);
	@$glb_magick = ();
	$glb_magick->Read(".toto.pnm");
	$glb_magick->Write("rgb/.toto.png");
}

sub correct {
	my($x, $t, $v) = @_;
	$x *= $t/$v;
	return $x;
}

sub auto_stretch {
	my($sz) = 320*200;
	my($min, $max) = (int($sz*7/100), int($sz*9/100));
	my($ok) = 0;
	my($bak) = "rgb/.autostretch.png";
	
	$glb_magick->Write($bak); 
	
	$glb_magick->ContrastStretch("$min,$sz");
	$glb_magick->Write("rgb/.autostretch0.png");
	my(@prof0) = &profile;
	
	@$glb_magick = ();
	$glb_magick->Read($bak);
	
	print "Contrast";
	
	while(!$ok && $max) {
		$ok = 0;
		$glb_magick->ContrastStretch($min.",".($sz-$max));
		$glb_magick->Write("rgb/.autostretch1.png");
		my(@prof1) = &profile;

		$ok = &profile_diff(@prof0, @prof1);
		if(!$ok) {
			$| = 1; print "."; $| = 0;
			@$glb_magick = ();
			$glb_magick->Read($bak);
			$max = int($max*.9);
		}
	}
	
	print " $max\n";
	
	@$glb_magick = ();
	$glb_magick->Read($bak);
	$glb_magick->ContrastStretch($min.",".($sz-$max));	
	$glb_magick->Write($bak);
}

sub profile {
	my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	my($l) = 3;
	my(@c) = (0) x ($l*3);
	my($i, $v);
	for($i=0; $i<$#t; $i+=3) {
		$rvb = 0;
		$v = int($l*$t[$i+0]); $v = $l-1 if $v>=$l; ++$c[$v];
		$v = int($l*$t[$i+1]); $v = $l-1 if $v>=$l; ++$c[$v+$l];
		$v = int($l*$t[$i+2]); $v = $l-1 if $v>=$l; ++$c[$v+$l+$l];
	}
	return @c;
}

sub profile_diff {
	my(@v) = @_;
	my($s) = ($#v+1)/6;
	my(@r1) = splice(@v,0,$s);
	my(@g1) = splice(@v,0,$s);
	my(@b1) = splice(@v,0,$s);
	my(@r2) = splice(@v,0,$s);
	my(@g2) = splice(@v,0,$s);
	my(@b2) = splice(@v,0,$s);
	#print join(",", @r1), "\n", join(",", @r2), "\n";
	#print join(",", @g1), "\n", join(",", @g2), "\n";
	#print join(",", @b1), "\n", join(",", @b2), "\n";
	return &profile_cmp($r1[$#$r1], $r2[$#r2]) && &profile_cmp($g1[$#$r1], $g2[$#r2]) && &profile_cmp($b1[$#$r1], $b2[$#r2]);
}

sub profile_cmp {
	my($vr, $v) = @_;
	my($tol) = 2;
	if($vr>640 && $v>640 && $v>$tol*$vr) {
		#print "==> $vr $v\n";
		return 0;
	}
	return 1;
}

sub profile_ {
	my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>200, normalize=>"True");
	my($l) = 3;
	my(@c) = (0) x ($l*$l*$l);
	my($i, $rvb, $v);
	for($i=0; $i<$#t; $i+=3) {
		$rvb = 0;
		$v = int($l*$t[$i+0]); $v = $l-1 if $v>=$l; $rvb = $rvb*$l + $v;
		$v = int($l*$t[$i+1]); $v = $l-1 if $v>=$l; $rvb = $rvb*$l + $v;
		$v = int($l*$t[$i+2]); $v = $l-1 if $v>=$l; $rvb = $rvb*$l + $v;
		++$c[$rvb];
	}
	return @c;
}

sub profile_diff_ {
	my($tol, @v) = @_;
	my($s) = ($#v+1)>>1;
	for($i=1; $i<$s; ++$i) {
		if($v[$i]>320 && $v[$s+$i]>320 && !($v[$i]*(1-$tol)<=$v[$s+$i] && $v[$s+$i]<=$v[$i]*(1+$tol))) {
			print " $i ==> $v[$i] / ".$v[$s+$i]."\n";
			return 0;
		}
	}
	return 1;
}

sub ammag {
	return $_[0] unless $glb_gamma;
	my $t = $_[0]/255;
	if($t<=0.018) {$t = 4.5*$t;} else {$t = 1.099*($t**(1/$glb_gamma))-0.099;}
	#$t = $t**(1/$glb_gamma);
	return xint(255*$t);
}

sub gamma {
	return $_[0] unless $glb_gamma;
	my $t = $_[0]/255;
	if($t<=0.081) {$t = $t/4.5;} else {$t = (($t+0.099)/1.099)**$glb_gamma;}
	#$t = $t**$glb_gamma;
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
		my($d, $t) = 0;
		$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $d += $t*$t; $rgb1>>=10; $rgb2>>=10;
		$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $d += $t*$t; $rgb1>>=10; $rgb2>>=10;
		$t = &irgb2sgn($rgb1) - &irgb2sgn($rgb2); $d += $t*$t; $rgb1>>=10; $rgb2>>=10;
		return sqrt($d);
		#return &irgb_module(&irgb_sub($rgb1, $rgb2));
	}
}

sub irgb2sgn {
	my($v) = @_;
	$v &= 0x1FF;
	return $v & 0x100 ? -(($v ^ 0x1FF)+1) : $v;
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
	my(@t, $i, $t);
	my(@r) = @_;
	
	# les composantes bien trop faibles sont eliminées
	for $i (@r) {
		my($r) = ($i>>00) & 0xFF;
		my($g) = ($i>>10) & 0xFF;
		my($b) = ($i>>20) & 0xFF;
		my($m) = $r;
		$m = $g if $g>$m;
		$m = $b if $b>$m;
		#$m = $m*3 + $r + $g + $b;
		#$m /= 16;
		if(1) {
			$m /= 4.2; # pas mal
			$m = 255/8 if $m>255/8;
			
			#while(($r<$m && $g<$m) || ($r<$m && $b<$m) || ($g<$m && $b<$m)) {$m/=1.05; last if $m<1e-3;}
			$r = 0 if $r < $m;
			$g = 0 if $g < $m;
			$b = 0 if $b < $m;
		} else {
			my($n) = $r;
			$n = $g if $g<$n;
			$n = $b if $b<$n;
			if($n<$m/8) {
				$r = 0 if $r <= $n*2;
				$g = 0 if $g <= $n*2;
				$b = 0 if $b <= $n*2;
			}
		}
		push(@t, ((($b<<10)|$g)<<10)|$r);
	}
	@r = @t; @t = ();
	
	# on elimine les composantes plus faibles que 10% du max
	for($i=0; $i<=$#r; $i+=8) {
		my($maxr, $maxv, $maxb) = (0, 0, 0);
		my($minr, $minv, $minb) = (1, 1, 1);
		my($rgb, @rgb);
		my(@o) = @r[$i..$i+7];
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
    for $i (@octet) {$i = &irgb_sat($i);}
    @octet = &cleanup(@octet);
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
	$px[$i+1] = &irgb_sprd($px[$i+1], &irgb_sub($rgb, $glb_pal[$jm]), $rgb, \@glb_ostr2) if $i<7;
    }
    
    # on efface les valeurs trop petites
    #for $i (keys %cpt) {delete $cpt{$i} unless $cpt{$i}>1;}
    
    my(@cpt) = (sort { $cpt{$b} - $cpt{$a} } keys %cpt);
    
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
		    $px[$j+1] = &irgb_sprd($px[$j+1], &irgb_sub($px[$j], $rgb), $px[$j], \@glb_ostr2) if $j<7;
                }
		#$d += &irgb_module($delta);
            }
            if($d < $dm) {$dm = $d; $im = $i;}
        }
        print "o";
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
		my($err) = &irgb_sub($px[$k], $rgb);
		#print $k,"->", &irgb2hex($octet[$k]),"#", &irgb2hex($px[$k]),":", &irgb2hex($rgb),"=",$d," err=", &irgb2hex($err),"\n";
		$px[$k+1] = &irgb_sprd($px[$k+1], $err, $px[$k], \@glb_ostr2) if $k<7;
            }
	    #print "DDDDD ",irgb2hex($delta),"\n";
	    #$d += &irgb_module($delta);
	    if($d < $dm) {$rm = $r; $dm = $d; $im = $i; $jm = $j;
		#print $i,",",$j, "==", &irgb2hex($glb_pal[$i])," ",&irgb2hex($glb_pal[$j])," == ",$d," (",$dm,") r=$r\n";
            }
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
	#print "\n\n";
	#for $t (@octet) {
	#	print &irgb2hex($t), " ";
	#}
	#print "\n\n";
	#for $t (@cpt) {
	#	print &irgb2hex($glb_pal[$t]), " ", $cpt{$t}, "\n";
	#}
	#die "XX=$rm $cpt[0]";
        $jm = $cpt[0]; 
        for($dm=1e30, $i=0; $i<$glb_maxcol; ++$i) {
            next if $i==$jm;
            @px = (@octet);
            for($d = $j = 0; $j<8 && $d<$dm; ++$j) {
                $d1 = &irgb_dist($glb_pal[$i ], $px[$j]);
                $d2 = &irgb_dist($glb_pal[$jm], $px[$j]);
                if($d1<$d2) {$rgb = $glb_pal[$i]; $d += &sq($d1);} else {$rgb = $glb_pal[$jm]; $d += &sq($d2);}
		$px[$j+1] = &irgb_sprd($px[$j+1], &irgb_sub($px[$j], $rgb), $px[$j], \@glb_ostr2) if $j<7;
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
    my($name, @px) = @_;
    
    my($i, $t);
    
    # récupération de la palette RGB
    my(%pal);
    foreach $i (@px) {++$pal{$i};}   
    #my(@t) = (sort { $pal{$b} - $pal{$a} } keys %pal);
    my(@t) = (sort { &irgb_module($a) - &irgb_module($b) } keys %pal);
    die "trop de couleurs ($#t)" if $#t>15;
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
        die "trop de couleur pour l'octet $i ($#t)" if $#t>1;

        # 1 seule couleur.. on essaye de récuperer les couleurs de la ligne d'avant si possible
        if($#t==0) {
            if($t[0] == $cols[$idx]) {
                $t[1] = $cols[$idx+1];
            } elsif($t[0] == $cols[$idx+1]) {
                $t[1] = $cols[$idx];
            } else {
                $t[1] = 0;
            }
        }
        @cols[$idx..$idx+1] = @t;
        $idx=0 if ($idx+=2)==80;

        my($forme, $fond) = ($t[0], $t[1]);
        %col = ();
        # pour l'instant 
        $t = 0;
        for($j=0; $j<8; ++$j) {
            $t += (128>>$j) if $octet[$j]==$forme;
        }
        $forme = $rgb2pal{$forme};
        $fond = $rgb2pal{$fond};
        # pour favoriser les répétitions en ramb, on fait $forme<=$fond
        if($forme <= $fond) {
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
        24,
        # ram a
        &to7_comp(@rama),
        0, 0,
        # ram b
        &to7_comp(@ramb),
        0, 0);
    
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
	return "rgb/.watchdog";
}

sub reset_wd {
	unlink &wd_file;
}

sub start_wd {
	my($pause) = 300;
	my($child) = fork;
	die "fork failed" unless defined $child;
	return unless $child;
	while(-e "$stopme") {
		for($i=0; $i<20 && -e "$stopme"; ++$i) {sleep($pause/20);}
		my($f) = &wd_file;
		if(-f $f) {
			reset_wd;
			kill 9, $child;
			die "Watch dog detected inactivity for $pause sec, exiting";
		} else {
			open(WDFILE,">$f");close(WDFILE);
		}
	}
}
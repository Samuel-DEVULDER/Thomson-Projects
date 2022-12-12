#/bin/perl

#use Graphics::Magick;
use Image::Magick;
use MIME::Base64 qw( encode_base64 );

$glb_dith   = ("default", "3x3", "4x4", "6x6", "8x8", "ostro94", "vac-14x14", "vac-25x25")[0];
$glb_target = ("zx","to","oric")[1];
$glb_satur  = 130;
$glb_blur   = 0;

$t = 255;
@glb_pal    = (0,0,0, $t,0,0, 0,$t,0, $t,$t,0, 0,0,$t, $t,0,$t, 0,$t,$t, $t,$t,$t);

if($glb_target eq "zx") {
$glb_width  = 256;
$glb_height = 192;
$glb_bloc_w = 8;
$glb_bloc_h = 8;
$glb_blur   = 1;
$t = 170;
push(@glb_pal, 0,0,0, $t,0,0, 0,$t,0, $t,$t,0, 0,0,$t, $t,0,$t, 0,$t,$t, $t,$t,$t);
}

if($glb_target eq "to") {
$glb_width  = 320;
$glb_height = 200;
$glb_bloc_w = 8;
$glb_bloc_h = 1;
$t = 170;
push(@glb_pal, 0,0,0, $t,0,0, 0,$t,0, $t,$t,0, 0,0,$t, $t,0,$t, 0,$t,$t, $t,$t,$t);
#push(@glb_pal, 193,193,193, 219,142,142, 142,219,142, 219,219,142, 142,142,219, 219,142,219, 193,249,249, 226,193,0);
}

if($glb_target eq "oric") {
$glb_width  = 240;
$glb_height = 200;
$glb_bloc_w = 6;
$glb_bloc_h = 1;
$glb_dith   = "5x3";
}

$pal = &px2img((1+$#glb_pal)/3, 1, @glb_pal);
$pal->Set(colorspace=>"sRGB");
@glb_lpal = $pal->GetPixels(channel=>"RGB", height=>1, normalize=>"True");
$glb_pal = int((1+$#glb_pal)/3)-1;
		
@glb_files = @ARGV;
if(!@glb_files) {
	print "No file found, reading from STDIN...";
	while(<STDIN>) {
		chomp;
		y%\\%/%;
		s%^([\S]):%/cygdrive/$1%;
		push(@glb_files, $_);
	}
	print "done\n";
}


# creation dossier de sortie
mkdir("rgb") || die "rgb: $!" unless -d "rgb";
for my $i (0..$#glb_files) {
	my $file = $glb_files[$i];

	my $out = $file;
	$out =~ s/.*[\\\/]//;
	next if $out =~ /\.(txt|htm.*|ps|pdf)$/i;
	next if $out =~ /rgb/;
	print 1+$i,"/",1+$#glb_files," ",$file,"\033]0;$out\007\n";
	$out =~ s/[\.][^\.]*//;
	$out = "rgb/$out.gif";
	next if -f $out;
	
	my $conv = &convert($file);
	next unless $conv;

	$conv->Set(colorspace=>"sRGB");
	$conv->Write($out);
	undef $conv;
	sleep(10);
}

sub convert {
	my($file) = @_;

	# read image
	my $img = Image::Magick->new();
	my $x=$img->ReadImage($file); 
	if($x) {print STDERR $x; return undef;}
	#$img->SetPixel(x=>0, y=>0, color=>[0xCD/255,0,0]);
	
	$img->Set(depth=>16);
	$img->Set(colorspace=>"RGB");
	#print join(',', $img->GetPixel(0,0)),"\n";
	$img->AutoLevel();
	$img->Normalize();
	$img->Modulate(saturation=>$glb_satur);
	#$img->Set(fuzz=>"5%");
	$img->Trim();
	$img  = &liqrz($img,$glb_width,$glb_height);
	$img->Blur(sigma=>$glb_blur) if $glb_blur;

	#sleep(15);

	# creation image 80x75
	my @px = $img->GetPixels(map=>"RGB", height=>$glb_height, width=>$glb_width, normalize=>"True");
	
	#for my $p (@px) {$p = 1/2 + 4/16;}
	
	# ajout du dither
	my @dither = ( [ 7, 13, 11, 4],
                       [12, 16, 14, 8],
  		       [10, 15,  6, 2],
 		       [ 5,  9,  3, 1] );

	# bayer 2x2
	@dither = ( [ 1,   4],
		    [ 3,   2]) if $glb_dith eq "2x2";
		    
	# ordered 3x3
	@dither = ( [3, 7, 4],
		    [6, 1, 9],
		    [2, 8, 5]) if $glb_dith eq "3x3";
	# better
	@dither = ( [7, 8, 2],
		    [6, 9, 4],
		    [3, 5, 1]) if $glb_dith eq "3x3";
	
	# bayer 4x4
	@dither = ( [ 1,   9,   3,  11],
		    [13,   5,  15,   7],
		    [ 4,  12,   2,  10],
                    [16,   8,  14,   6]) if $glb_dith eq "4x4";
		    
	# Halftone 6x6
	@dither = ( [14, 13, 10,  8,  2,  3],
		    [16, 18, 12,  7,  1,  4],
		    [15, 17, 11,  9,  6,  5],
		    [ 8,  2,  3, 14, 13, 10],
		    [ 7,  1,  4, 16, 18, 12],
		    [ 9,  6,  5, 15, 17, 11] ) if $glb_dith eq "6x6";
		  
	# bayer 8x8
	@dither = 	   ( [ 1,  49,  13,  61,   4,  52,  16,  64],
			     [33,  17,  45,  29,  36,  20,  48,  32],
                             [ 9,  57,   5,  53,  12,  60,   8,  56],
                             [41,  25,  37,  21,  44,  28,  40,  24],
                             [ 3,  51,  15,  63,   2,  50,  14,  62],
                             [35,  19,  47,  31,  34,  18,  46,  30],
                             [11,  59,   7,  55,  10,  58,   6,  54],
			     [43,  27,  39,  23,  42,  26,  38,  22]) if $glb_dith eq "8x8";
		
	# void and cluster 14x14
	@dither = (
	 [132, 188,   9,  79,  51,  19, 135,  90, 156, 103,  30,  96, 185,  74],
	 [ 23,  87, 114, 172, 143, 106,  35, 167,  10,  61, 152, 129,  41, 111],
	 [169, 138,  46,  29,  65, 189,  83,  55, 125, 190,  81,  14, 157,  57],
	 [  8,  62, 187, 122, 155,   7, 109, 178,  25, 101,  39, 177,  94, 124],
	 [ 84, 149,  97,  18,  89, 134,  45, 146,  70, 162, 140,  73,  31, 182],
	 [116,  28, 164,  48, 179,  66, 165,  15, 121,  49,   6, 128, 154,  53],
	 [191,  59, 127,  82, 117,  22, 107,  78, 174,  93, 192,  64, 100,  13],
	 [ 77, 145,   5, 186,  38, 150, 193,  40, 136,  24, 118,  32, 171, 133],
	 [ 36, 173, 104,  67, 130,  80,   4,  98,  58, 160,  71, 142,  54,  95],
	 [115,  21,  50, 159,  20, 147, 170, 123, 184,  12, 105, 181,   3, 166],
	 [153,  88, 183, 119,  92,  43,  68,  26,  85, 148,  44,  86, 126,  69],
	 [ 17, 137,  72,  11, 194, 113, 161, 139,  52, 112, 163,  27, 195,  47],
	 [175, 108,  42, 144,  34,  75,   2, 102, 196,  16,  76, 141, 110,  91],
	 [ 33,  63, 158,  99, 168, 120, 180,  60,  37, 131, 176,  56,   1, 151]
	) if $glb_dith eq "vac-14x14";
	
	# void and cluster 25x25
	@dither = (
	[166,531,107,303,541,220,478,101,232,418,315,224,425, 38,208,435,327, 23,449,339,112,455,524,279,580],
	[335, 20,411,496, 58,353,159,319,599,110,510,158,525,283,607, 84,226,540,164,235,608,314,207, 72,471],
	[252,609,217,136,276,610,416, 30,452,205,398, 22,374,108,463,349,483,121,363,509, 34,148,573,389,143],
	[448, 78,346,566,440,105,216,547,280, 70,568,312,586,259,178, 18,267,602, 56,429,271,462,332, 27,561],
	[ 65,272,487,187, 17,337,458,151,343,472,246,162, 57,397,497,556,386,147,322,191,527, 98,183,512,298],
	[430,554, 50,375,537,264,576, 44,502,125,369,539,451,122,310, 85,211,450,562, 80,357,611,257,379, 59],
	[106,316,157,245,424,119,184,409,221,612, 16,199,294,597,222,376,582, 40,239,501,288, 15,438,140,596],
	[538,360, 92,601,476,213,526,169,559,129,456,371,180,302,406,210,468, 49,443,128,356,185,333,482,127],
	[287,176,437,274, 32,378,307, 37,413,295,617,  9,474, 61,604,117,348,533,192,569, 62,523, 91,219,392],
	[593, 63,515,123,553,150,618,242,514, 82,203,273,558,334,227,508,256, 73,306,403,230,419,297,552,  8],
	[412,318,237,417,338,481, 65,390,133,351,488,405, 90,163,436, 45,420,619,114,506, 21,605,139,466,189],
	[494,134,581,  7,170,260,321,549,194,594, 41,179,513,365,592,145,320,197,387,262,352,206,385, 77,270],
	[ 39,350,209,505,441,100,491,  6,427,244,323,575,282,  5,238,461,528,  4,550,156,578, 48,534,317,620],
	[395,520, 83,269,326,567,200,300,120,530, 76,401,126,493,345, 87,218,309,464, 81,396,285,475,118,202],
	[ 96,236,423,621,144, 46,373,598,454,344,186,480,248,570,172,410,585,130,366,240,489, 95,225,439,560],
	[284,542, 19,195,402,517,263,149, 42,251,622, 25,330, 93,447, 28,292,486, 36,623,181,536,380, 31,342],
	[444,146,364,495,247,102,446,551,391,500,116,433,522,212,624,254,529,190,431,308, 54,324,131,625,173],
	[ 47,590,293, 64,600,329,204, 75,291,182,377,275,141,394, 60,368, 89,381,138,507,253,572,432,241,498],
	[383,229,465,168,399,  3,574,367,519,  2,584, 74,564,304,511,155,565,258,588, 66,407,174,  1,361,111]
	) if $glb_dith eq "vac-25x25";
	
	# rotated dispersed dither
	@dither = (
	[15, 7, 10, 4, 8, 3, 11, 7, 13, 12, 14, 6, 11, 1, 5, 2, 10, 6, 16, 9],
	[5, 2, 6, 16, 1, 9, 15, 10, 4, 16, 8, 3, 7, 13, 4, 12, 14, 11, 1, 13],
	[12, 8, 14, 11, 13, 5, 12, 2, 6, 1, 9, 5, 15, 10, 16, 8, 9, 3, 7, 4],
	[16, 9, 3, 15, 7, 4, 8, 14, 3, 11, 13, 12, 2, 14, 6, 1, 5, 15, 2, 10],
	[11, 1, 5, 2, 10, 6, 16, 9, 15, 7, 10, 4, 8, 3, 11, 7, 13, 12, 14, 6],
	[7, 13, 4, 12, 14, 11, 1, 13, 5, 2, 6, 16, 1, 9, 15, 10, 4, 16, 8, 3],
	[15, 10, 16, 8, 9, 3, 7, 4, 12, 8, 14, 11, 13, 5, 12, 2, 6, 1, 9, 5],
	[2, 14, 6, 1, 5, 15, 2, 10, 16, 9, 3, 15, 7, 4, 8, 14, 3, 11, 13, 12],
	[8, 3, 11, 7, 13, 12, 14, 6, 11, 1, 5, 2, 10, 6, 16, 9, 15, 7, 10, 4],
	[1, 9, 15, 10, 4, 16, 8, 3, 7, 13, 4, 12, 14, 11, 1, 13, 5, 2, 6, 16],
	[13, 5, 12, 2, 6, 1, 9, 5, 15, 10, 16, 8, 9, 3, 7, 4, 12, 8, 14, 11],
	[7, 4, 8, 14, 3, 11, 13, 12, 2, 14, 6, 1, 5, 15, 2, 10, 16, 9, 3, 15],
	[10, 6, 16, 9, 15, 7, 10, 4, 8, 3, 11, 7, 13, 12, 14, 6, 11, 1, 5, 2],
	[14, 11, 1, 13, 5, 2, 6, 16, 1, 9, 15, 10, 4, 16, 8, 3, 7, 13, 4, 12],
	[9, 3, 7, 4, 12, 8, 14, 11, 13, 5, 12, 2, 6, 1, 9, 5, 15, 10, 16, 8],
	[5, 15, 2, 10, 16, 9, 3, 15, 7, 4, 8, 14, 3, 11, 13, 12, 2, 14, 6, 1],
	[13, 12, 14, 6, 11, 1, 5, 2, 10, 6, 16, 9, 15, 7, 10, 4, 8, 3, 11, 7],
	[4, 16, 8, 3, 7, 13, 4, 12, 14, 11, 1, 13, 5, 2, 6, 16, 1, 9, 15, 10],
	[6, 1, 9, 5, 15, 10, 16, 8, 9, 3, 7, 4, 12, 8, 14, 11, 13, 5, 12, 2],
	[3, 11, 13, 12, 2, 14, 6, 1, 5, 15, 2, 10, 16, 9, 3, 15, 7, 4, 8, 14]
	) if $glb_dith eq "ostro94";
	
	@dither = (
	[ 3, 9, 4],
	[ 8,14,10],
	[13,15,11],
	[ 7,12, 5],
	[ 2, 6, 1]
	) if $glb_dith eq "5x3";
		
	my($dmax) = 0;
	for my $r (@dither) {for my $d (@$r) {$dmax = $d if $d>$dmax;}}
	for my $r (@dither) {for my $d (@$r) {$d/=($dmax+1);}}
	
	my(@di);
	for my $y (0..$glb_height-1) {for my $x (0..$glb_width-1) {
		push(@di, ($dither[$y%(1+$#dither)][$x%(1+$#{$dither[0]})])x3);
	}}
	
	# conversion
	my @conv = (0)x($glb_width*$glb_height);
	for my $y (0..($glb_height/$glb_bloc_h-1)) {
	#for my $y (0..0) {
		$y *= $glb_bloc_h;
		for my $x (0..($glb_width/$glb_bloc_w-1)) {
		#for my $x (28..28) {
			$x *= $glb_bloc_w;
			my(@bloc, @err);
			for my $j ($y..$y+$glb_bloc_h-1) {for my $i ($x..$x+$glb_bloc_w-1) {
				my $p = ($i + $j*$glb_width)*3;
				push(@bloc, @px[$p..$p+2]);
				push(@err,  @di[$p..$p+2]);
			}}
			my($c1, $c2) = &find(\@bloc, \@err);
			for my $j ($y..$y+$glb_bloc_h-1) {for my $i ($x..$x+$glb_bloc_w-1) {
				my $p = ($i + $j*$glb_width);
				my($ignore, $c) = 
				#&match2(\@px, \@di, $p*3);
				&match($c1, $c2, \@px, \@di, $p*3);
				$conv[$p] = $c;
			}}
		}
	}

	# generation image sortie
	my @out;
	for my $c (@conv) {
		push(@out, @glb_pal[$c*3..$c*3+2]);
	}
	
	#for my $i (0..$#out>>1) {$out[$i] = int($px[$i]*255);}
	
	# sortie
	return &px2img($glb_width, $glb_height, @out);
	
	return $img;
}

sub find {
	my($px, $err) = @_;
	
	my($bd, @c) = (1e38, 0, 0);
	for my $c1 (0..$glb_pal-1) {for my $c2 ($c1+1..$glb_pal) {
		next if $glb_target eq "zx" && (($c2|$c1) & 8);
	
		my $d = &dist($c1, $c2, $px, $err, $bd);
		if($d<$bd) {$bd = $d; @c = ($c1, $c2);}
	}}
	
	if($glb_target eq "zx") {
		my $max = 0; for my $i (0..$#{$px}) {my $v = $px->[$i]+($err->[$i]-0.5)/2; $max = $v if $v>$max;}
		if($max<=0.5) {
			for my $c1 (8..14) {for my $c2 ($c1+1..15) {
				my $d = &dist($c1, $c2, $px, $err, $bd);
				#print "$c[0],$c[1]   $bd   ($c1,$c2, $d)\n";
				if($d<$bd) {$bd = $d; @c = ($c1, $c2);}
			}}
		}
	}
	return @c;
}

sub dist {
	my($c1, $c2, $px, $err, $thr) = @_;
	
	my $d = 0;
	for(my $i=0; $d<=$thr && $i<$#{$px}; $i+=3) {
		my ($t, $ignore) = &match($c1, $c2, $px, $err, $i);
		$d += $t;
	}
	return $d;
}

sub match {
	my($c1, $c2, $px, $err, $o) = @_;

	my(@p1) = @glb_lpal[$c1*3..$c1*3+2];
	my(@p2) = @glb_lpal[$c2*3..$c2*3+2];
	
	my(@p);
	for my $i (0..2) {$p[$i] = $px->[$o+$i] + ($err->[$o+$i]-0.5)*.70;} 
	
	
	my $d1 = &dist2(@p, @p1);
	my $d2 = &dist2(@p, @p2);
	
	#print join(',', int($px->[$o+0]*256),int($px->[$o+1]*256),int($px->[$o+2]*256),"   t=",$t,$d1-$d2),"\n";
	return $d1<$d2 ? ($d1, $c1) : ($d2, $c2);
}

sub match2 {
	my($px, $di, $o) = @_;
	my($best, $c) = 1e38;
	
	for my $c1 (0..6) {for my $c2 ($c1+1..7) {
		my($a,$b) = &match($c1, $c2, $px, $di, $o);
		if($a<$best) {$best = $a; $c = $b;}
	}}
	for my $c1 (8..14) {for my $c2 ($c1+1..15) {
		my($a,$b) = &match($c1, $c2, $px, $di, $o);
		if($a<$best) {$best = $a; $c = $b;}
	}}
	return ($best, $c);
}

sub min {
	my($m) = $_[0];
	for my $x (@_) {$m = $x if $x<$m;}
	return $m;
}

sub liqrz {
	my($img, $t_width, $t_height) = @_;
	
	my $width  = $img->Get('width');
	my $height = $img->Get('height');

	my $rotate = 0;
	if(int($t_width * $height / $width+.5)>$t_height) {
		$rotate = 1;
		($width, $height)     = ($height, $width);
		($t_width, $t_height) = ($t_height, $t_width);
		$img->Rotate(degrees=>90);
	}
	
	$img->AdaptiveResize(geometry=>int($t_height * $width / $height+.5)."x".($t_height), filter=>"lanczos", blur=>1.5);

	$img->Set(colorspace=>"sRGB");
	$img->Write('rgb/zzzzzzzzzz.png');

	$width  = $img->Get('width');
	$height = $img->Get('height');
	
	local(@img, @gry, @nrj);
	for my $y (0..$height-1) {
		push(@img, [$img->GetPixels(map=>"RGB", height=>1, width=>$width, x=>0, y=>$y, normalize=>"True")]);
		push(@gry, [$img->GetPixels(map=>"I", height=>1, width=>$width, x=>0, y=>$y, normalize=>"True")]);
		push(@nrj, [(0) x $width]);
	}
	
	# fonction energie
	my $sobel = sub {
		my($x, $y) = @_;
		
		my $py = $y-1;
		my $ny = $y+1;
		my $cy = $y;
		$py = 0         if $py<0;
		$ny = $height-1 if $ny >= $height;
		
		my $px = $x-1;
		my $nx = $x+1;
		my $cx = $x;
		$px = 0        if $px<0;
		$nx = $width-1 if $nx>=$width;
			
		my $ipp = $gry[$py]->[$px];
		my $icp = $gry[$py]->[$cx];
		my $inp = $gry[$py]->[$nx];
		
		my $ipc = $gry[$cy]->[$px];
		my $inc = $gry[$cy]->[$nx];
			
		my $ipn = $gry[$ny]->[$px];
		my $icn = $gry[$ny]->[$cx];
		my $inn = $gry[$ny]->[$nx];
		
		my ($c1, $c2, $c3, $c4) = (2,1, 2,1);
		my $gx = ($inc-$ipc)*$c1+(($inp-$ipp)+($inn-$ipn))*$c2;
		my $gy = ($icn-$icp)*$c3+(($ipn-$ipp)+($inn-$inp))*$c4;
			
		return sqrt($gx*$gx + $gy*$gy);
	};
	my $gradient = sub {
		my($x, $y) = @_;
		
		my $py = $y-1;
		my $ny = $y+1;
		$py = 0         if $py<0;
		$ny = $height-1 if $ny >= $height;
		
		my $px = $x-1;
		my $nx = $x+1;
		$px = 0        if $px<0;
		$nx = $width-1 if $nx>=$width;
			
		return sqrt(($gry[$py]->[$x]-$gry[$ny]->[$x])**2 + ($gry[$y]->[$px]-$gry[$y]->[$nx])**2);
	};
	my $gradient_x = sub {
		my($x, $y) = @_;
		
		my $px = $x-1;
		my $nx = $x+1;
		$px = 0        if $px<0;
		$nx = $width-1 if $nx>=$width;
			
		return abs($gry[$y]->[$px]-$gry[$y]->[$nx]);
	};
	my $energy = $gradient_x;

	for my $y (0..$height-1) {for my $x (0..$width-1) {
		$nrj[$y]->[$x] = $energy->($x,$y);
	}}
	
	if(1) {
	my @px; my $max;
	for my $r (@nrj) {for my $e (@$r) {$max = $e if $e>$max;}}	
	for my $r (@nrj) {for my $e (@$r) {push(@px, (int($e*256/($max+1)))x3);}}
	
	my $img2 = &px2img($width, $height, @px);
	$img2->Write('rgb/zzzzzzzzz.png');
	}

	while($width > $t_width) {
		if(0) {
			my @px; my $max;
			for my $r (@nrj) {for my $e (@$r) {$max = $e if $e>$max;}}	
			for my $r (@nrj) {for my $e (@$r) {push(@px, (int($e*256/($max+1)))x3);}}
			my $img2 = &px2img($width, $height, @px);
			$img2->Write('rgb/zzzzzzzzz.png');
		}
		print STDERR "$width    \r";
		# Dijkstra
		my (@dir, @nrj2);
		for my $y (0..$height-1) {push(@dir, [(0)x$width]);}
		my (@min) = @{$nrj[0]};
		my($nrj2) = 0;
		push(@nrj2, [@min]) if $nrj2;
		for my $y (1..$height-1) {
			my(@m1n, $dir, $min);
			for my $x (0..$width-1) {
				my(@p) = ($x);
				push(@p, $x-1) if $x>0;
				push(@p, $x+1) if $x<$width-1;
				#push(@p, $x-2) if $x>1;
				#push(@p, $x+2) if $x<$width-2;
				
				$min = $min[$dir = pop(@p)];
				for my $q (@p) {if($min[$q]<$min) {$min = $min[$dir=$q];}}
		
				$dir[$y]->[$x] = $dir;
				push(@m1n, $min + $nrj[$y]->[$x]);
			}
			@min = @m1n;
			push(@nrj2, [@min]) if $nrj2;
		}
		
		if($nrj2) {
			my($max, @px) = 1;
			for my $r (@nrj2) {for my $e (@{$r}) {$max = $e if $e>$max;}}	
			for my $r (@nrj2) {for my $e (@{$r}) {push(@px, (int($e*256/($max+1)))x3);}}
			my $img2 = &px2img($width, $height, @px);
			$img2->Write('rgb/zzzzzzzzz__.png');
		}
		
		#for my $m (@min) {print STDERR " ", int($m*100)/100;}print STDERR "\n";

		# find minima
		my ($min, $pos) = 1e38;
		for my $x (0..$width-1) {$min = $min[$pos = $x] if $min[$x]<$min;}
		last if $min>=1e38;
		#print STDERR "POS=$pos ($min)     ";
	
		# delete pixel
		my($smooth) = 0;
		for(my ($y,$p)=($height, $pos); --$y>=0; $p = $dir[$y]->[$p]) {
			my (@t) = splice($img[$y], $p*3, 3);
			if($smooth && $p>0) {
				for my $i (0..2) {
					$img[$y]->[3*$p+$i-3] = ($img[$y]->[3*$p+$i-3]+$t[$i])/2;
				}
			}
			if($smooth && $p<$width-1) {
				for my $i (0..2) {
					$img[$y]->[3*$p+$i] = ($img[$y]->[3*$p+$i]+$t[$i])/2;
				}
			}
			
			my ($t) = splice($gry[$y], $p, 1);
			if($smooth && $p>0) {
				$gry[$y]->[$p-1] = ($gry[$y]->[$p-1]+$t)/2;
			}
			if($smooth && $p<$width-1) {
				$gry[$y]->[$p] = ($gry[$y]->[$p]+$t)/2;
			}			
			splice($nrj[$y], $p, 1);
		}	
		
		--$width;
		# rebuild NRJ
		for(my ($y,$p)=($height, $pos); --$y>=0; $p = $dir[$y]->[$p]) {
			$nrj[$y]->[$p-1] = $energy->($p-1, $y) if $p>0;
			$nrj[$y]->[$p]   = $energy->($p  , $y) if $p<$width;
			
			$nrj[$y]->[$p-2] = $energy->($p-2, $y) if $smooth && $p>1;
			$nrj[$y]->[$p+1] = $energy->($p+1, $y) if $smooth && $p+1<$width;
		}
	}

	my @px;
	for my $r (@img) {for my $e (@$r) {push(@px, int($e*255));}}
	$img2 = &px2img($width, $height, @px);
	$img2->Write('rgb/zzzzzzzzzzz.png');

	if($rotate) {
		$img->Rotate(degrees=>-90);
		$img2->Rotate(degrees=>-90);
	}
	
	$img2->Set(depth=>16);
	$img2->Set(colorspace=>"RGB");
	
	#print "i>", $img->Get('colorspace'),"\n";
	#print "o>", $img2->Get('colorspace'),"\n";
	
	return $img2;
}

sub px2img {
    my($width,$height,@px) = @_;

    my $img2;
    if($#px>1000) {
        open(OUT,">/tmp/.toto2.pnm");print OUT "P6\n$width $height\n255\n",pack('C*', @px),"\n";close(OUT);
        $img2 = Image::Magick->new(colorspace=>"RGB");
        $img2->ReadImage("/tmp/.toto2.pnm");
        unlink "/tmp/.toto2.pnm";
    } else {
	my $txt = "P6\n$width $height\n255\n".pack('C*', @px)."\n";
	#system("convert 'inline:data:,".encode_base64($txt)."' toto.gif");
        $img2 = Image::Magick->new(colorspace=>"RGB");
        my $x = $img2->ReadImage("inline:data:image/pnm,".encode_base64($txt));
	warn $x."\n$width $height ".(1+$#px)/3 if $x;
    } 

    return $img2;
 }
 
 
sub dist2 {
	#return &dist2_simple(@_);
	#return &dist2_cielab(@_);
	return &dist2_cieapprox(@_);
	return &dist2_luma(@_);
}

sub dist2_simple {
	my $e = 0;
	$e += ($_[0]-$_[3])**2;
	$e += ($_[1]-$_[4])**2;
	$e += ($_[2]-$_[5])**2;
	
	return $e;
}

sub dist2_cielab {
	my($r1,$g1,$b1, $r2,$g2,$b2) = @_;

	my(@lab1) = &XYZ2LAB(&sRGB2XYZ($r1,$g1,$b1));
	my(@lab2) = &XYZ2LAB(&sRGB2XYZ($r2,$g2,$b2));
	
	my $e = 0;
	$e += ($lab1[0]-$lab2[0])**2;
	$e += ($lab1[1]-$lab2[1])**2;
	$e += ($lab1[2]-$lab2[2])**2;
	
	return $e;
}

sub dist2_cieapprox { # CIE Lab approximé http://www.compuphase.com/cmetric.htm#GAMMA
	my($r1,$g1,$b1, $r2,$g2,$b2) = @_;
	
	my($rMean) = ($r1+$r2)/2;
	my $e = 0;
	$e += ($r1 - $r2)**2 * (2 + $rMean);
	$e += ($g1 - $g2)**2 * (4 + 1);
	$e += ($b1 - $b2)**2 * (3 - $rMean);

	return $e;
}

sub dist2_luma { # Compare the difference of two RGB values, weigh by CCIR 601 luminosity:
	my($r1,$g1,$b1, $r2,$g2,$b2) = @_;
	
	$r1 -= $r2; $g1 -= $g2; $b1 -= $b2;
	#return $r1*$r1 + $g1*$g1 + $b1*$b1;
	
	my($l) = abs($r1)*.299 + abs($g1)*.587 + abs($b1)*.114;
	
	return ($r1*$r1*.299 + $g1*$g1*.587 + $b1*$b1*.114)*.75 + $l*$l;
}

sub sRGB2XYZ {
	my($R,$G,$B) = @_;
	my($f) = sub {my($x) = @_; return $x<=0.04045 ? $x/12.92 : (($x+0.055)/1.055)**2.4;};
	($R, $G, $B) = ($f->($R), $f->($G), $f->($B));
	
	return (0.4124*$R + 0.3576*$G + 0.1805*$B,
	        0.2126*$R + 0.7152*$G + 0.0722*$B,
		0.0193*$R + 0.1192*$G + 0.9505*$B);
}

sub RGB2XYZ {
	my($R,$G,$B) = @_;
	return (2.768892*$R + 1.751748*$G + 1.130200*$B,
	        1.000000*$R + 4.590700*$G + 0.060100*$B,
		              0.056508*$G + 5.594292*$B);
}

sub XYZ2LAB {
	my($X,$Y,$Z) = @_;
	
	@glb_XYZ = &sRGB2XYZ(1,1,1) unless @glb_XYZ;
	
	my($f) = sub {my($t) = @_; return $t>(6/29)**3 ? $t**(1/3) : 1/3*(29/6)**2*$t+4/29;};
	($X, $Y, $Z) = ($f->($X/$glb_XYZ[0]), $f->($Y/$glb_XYZ[1]), $f->($Z/$glb_XYZ[2]));
	
	return (116*$Y-16, 500*($X-$Y), 200*($Y-$Z));
}

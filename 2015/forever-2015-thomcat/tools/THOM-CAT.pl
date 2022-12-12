#/bin/perl

#use Graphics::Magick;
use Image::Magick;

$glb_width = 320;
$glb_height = 200;
$glb_resize = 1;

# read image
$img = Image::Magick->new();
$x=$img->ReadImage($ARGV[0]); die "$ARGV[0]: $x" if $x;
$img->Set(depth=>16);

# align all the images
$z = $img->[0]->Clone();
for(my($i,$l) = (1,$#{$img}); $i<=$l; ++$i) {
	my($d) = $img->[$i]->Get("delay");
	$z->Composite(image=>$img->[$i], compose=>"Over",
		      x=>$img->[$i]->Get("page.x"),
	              y=>$img->[$i]->Get("page.y"));
	$img->[$i] = $z->Clone();
	$img->[$i]->Set(delay=>$d);
}

# decide if image is pure B&W, and decide the most abundant color
$img->Set(type=>"grayscale");
$img->AutoLevel();
$img->Gamma(.8);
$img->Normalize();

@h=$img->Histogram();
$total = 0;
while(@h) {
    my ($r, $g, $b, $a, $count) = splice @h, 0, 5;
    $r = int($r*16/65536);
    $g = int($g*16/65536);
    $b = int($b*16/65536);
    my $k = "$r,$g,$b";
    my $h = $h{$k};
    $h = $h{$k} = {r => $r, g=>$g, b=>$b, k=>$k, n=>0} unless defined($h);
    $h->{n} += $count;
    $total += $count;
}
# Sort the colors in decreasing order
@h = sort { $h{$b}->{n} <=> $h{$a}->{n} } (keys %h);
for my $h (@h) {$h = $h{$h};}

# is the image bw ?
$bw = (($h[0]->{k} eq "0,0,0" || $h[0]->{k} eq "15,15,15") &&
       ($h[1]->{k} eq "0,0,0" || $h[1]->{k} eq "15,15,15")) && 
       ($h[0]->{n} + $h[1]->{n} > $total*.95);
       
# bg color
$bg = ("white", "black")[$h[0]->{k} eq "0,0,0"?1:0];
$bg = "white";
$img->Set(background=>$bg);

# make the image full screen
$img->Resize(geometry=>"320x200!");

# make the image two colors
$img->OrderedDither(threshold=>"v4")     unless $bw;
$img->Posterize(levels=>2, dither=>"False") if     $bw;

# find proper period
$len = 1+$#{$img};
$per = 0;
for(my $i=12; --$i>=0;) {
	if(($len % $i)==0) {$per = $i; last;}
}
die "Can't find period" unless $per;
print STDERR "len=$len per=$per\n";

#$img->[0]->Annotate(text=>"THOM-CAT (c) Plus 2015");

# save
$img->Write('tst.gif');

# build interleaved image
@px = ();
for my $y (0..199) {
	my @line = $img->[int(((199-$y)*$len/$per) % $len)]->GetPixels(map=>"RGB", height=>1, width=>320, x=>0, y=>$y, normalize=>"True");
	for(my $x=0; $x<320*3; $x+=3) {
		push(@px, ($line[$x]>0.5) != ($bg eq "white"));
	}
}

# generate data
$col = $bg eq "white" ?  7 : 0;
push(@data,
	0x14, # pas de curseur
	27, 0x40+$col, # forme
	27, 0x50+$col, # fond
	27, 0x60+$col, # tour
	12,   # effacement ecran
	27, 0x47-$col,
	unpack('C*', " "),
	0) if 0;
	
# trim top
$top = 0;
for my $i (0..$#px) {
	if($px[$i]!=$px[0]) {
		$top = int($i/320);
		last;
	}
}

# trim bottom
$bottom = 0;
for(my $i=$#px; $i>=0; --$i) {
	if($px[$i]!=$px[$#px]) {
		$bottom = int($i/320+1);
		last;
	}
}

print "top=$top\n";
print "bot=$bottom\n";
print "len=",$bottom-$top,"\n";
@px = @px[$top*320..$bottom*320];

#push(@data, $l>>8, $l&255);

# compress image
@data = ();
for(my $i=$#px; $i>=0;) {
	my $j = $i;
	while(--$i>=0 && $px[$i]==$px[$j]) {}
	
	my $l = $j - $i;
	--$l if $i<0;
	while($l>0) {
		my $code = $px[$j]?128:0;
		if($l>=256) {
			$l -= 256;
		} elsif($l>127) {
			$code |= 127;
			$l -= 127;
		} else {
			$code |= $l;
			$l = 0;
		}
		push(@data, $code);
	}
}

for(my($i,$l)=0; $i<$#data;) {
	print "\tfdb\t" if $l==0;
	print "," if $l>0;
	print sprintf("\$%04x", $data[$i]*256+$data[$i+1]);
	$i+=2;
	if(++$l==3 || $i>=$#data) {print "\n"; $l=0;}
}
print sprintf("\tfcb\t\$%02x\n", $data[$#data]) if ($#data & 1)==0;

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
$bg = ("white", "black")[$h[0]->{k} eq "0,0,0"];
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

# save
$img->Write('tst.gif');

# generate data
$col = $bg eq "white" ?  7 : 0;
push(@data, 
	0x14, # pas de curseur
	27, 0x40+$col, # forme
	27, 0x50+$col, # forme
	27, 0x60+$col, # tour
	12,   # effacement ecran
	0);

for my $y (0..199) {
	my @line = $img->[int(((199-$y)*$len/$per) % $len)]->GetPixels(map=>"RGB", height=>1, width=>320, x=>0, y=>$y, normalize=>"True");
	my $b = 1;
	for(my $x=0; $x<320*3; $x+=3) {
		$b <<= 1;
		$b |= ($line[$x]>0.5) == ($bg eq "white") ?1:0;
		if($b & 256) {
			push(@data, ($b&255) | 0);
			$b = 1;
		}	
	}
}

push(@data, ($per*40)>>8, ($per*40)&255);

open(OUT,'>anim.dat');
print OUT pack('C*', 0, int((1+$#data)/256), (1+$#data)&255, 0, 0);
print OUT pack('C*', @data);
print OUT pack('C*', 255, 0, 0, 0, 0);
close(OUT);

# $len = 1+$#{$img};
# for $i (2..$len-1) {
	# my $d = $img->[0]->Compare(image=>$img->[$i], metric=>"rmse");
	# if($d->Get('error')<0.01) {
		# $len = $i;
		# last;
	# }
# }
# print info
# print 1+$#{$img}, " frames";
# print " (reduced to $len)" if $len!=$#{$img}+1;
# print "\n";
# for $d (2, 3, 5, 7, 11, 13, 17, 23, 29, 41, 43, 47) {
	# print "is divisible by $d\n" if ($len % $d)==0;
# }

exit;

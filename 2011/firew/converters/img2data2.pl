#/bin/perl

#use Graphics::MagickXX;
use Image::Magick;

$glb_magick = Image::Magick->new;
$glb_magick->Read($ARGV[0]);
#$glb_magick->Enhance();
#$glb_magick->Normalize(); #
#$glb_magick->Set(antialias=>"True");
$glb_magick->SigmoidalContrast(contrast=>2);
$glb_magick->AdaptiveResize(geometry=>"80x50", filter=>"lanczos", blur=>1);
$glb_magick->Border(width=>"80",height=>"50",color=>"black");
$glb_magick->Set(gravity=>"Center");
$glb_magick->Crop(geometry=>"80x50!");
$glb_magick->Set(page=>"80x50+0+0");
$glb_magick->Resize(geometry=>"80x50!", filter=>"lanczos", blur=>1);
$glb_magick->Posterize(levels=>4, dither=>"True");
$glb_magick->Write("toto.png");

my(@t) = $glb_magick->GetPixels(map=>"RGB", height=>50, normalize=>"True");

for($c=0; $c<3; ++$c) {
	print "\necranR" if $c==0;
	print "\necranV" if $c==1;
	print "\necranB" if $c==2;
	$n = 0; $v=0; $u=0; $w=0;
	for($i=$c; $i<$#t; $i+=3) {
		$v = $v*16 + int($t[$i]*7+0.5);
		if(++$n==2) {
			$n = 0;
			if(++$u==1) {
				print "\n\tfcb\t$v";
			} else {
				print ",$v";
				$u = 0 if $u==5;
			}
			if(++$w==40) {
				$u = $w = 0;
				print "\n\tfdb\t0";
			}
			$v=0;
		}
	}
}

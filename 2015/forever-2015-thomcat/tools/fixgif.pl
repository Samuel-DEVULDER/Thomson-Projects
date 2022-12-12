#/bin/perl

#use Graphics::Magick;
use Image::Magick;

# read image
for $f (@ARGV) {
	print $f, "\n";
	$img = Image::Magick->new();
	$x=$img->ReadImage($f); die "$f: $x" if $x;
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
	
	$img->WriteImage($f);
}

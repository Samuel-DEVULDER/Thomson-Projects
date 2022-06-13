@n = (); $a=0; $c=0;
$_ = <>; $_ = <>; $_ = <>; $_ = <>;
print "\tfcb\t";
while(<>) { 
	foreach (split) {
		@n = (@n, int(3*$_/255));
		if($#n==2) {
			$v = ($n[0]*16+$n[1]*4+$n[2]);
			print $v*3;
			++$c;
			@n=(); 
			if(++$a==6) {
				$a=0; 
				print "\n\tfcb\t";
			} elsif($c != 256) {
				print ",";
			}
		}
	}
}
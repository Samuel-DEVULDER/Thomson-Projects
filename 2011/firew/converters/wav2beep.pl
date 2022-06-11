#!/bin/perl

$name = $ARGV[0];

# convert WAV file to compressed thomson format (2 samples per byte)
use Audio::Wav;

# read WAV FILE
my $wav = new Audio::Wav;
my $data= $wav->read( $name );
my $maxind= $data->length();
my $seconds= $data->length_seconds();
my $wavFreq = $maxind/$seconds;

@input = ();
for(my $i=0; $i<$maxind; ++$i) {
	my @chanels = $data->read();
	last unless @chanels;
	my $v = 0; my $t;
	for $t (@chanels) {$v += $t;}
	push(@input, $v/(1+$#chanels));
}

# center
my $center = 0;
my $t;
for $t (@input) {$center += $t;}
$center /= 1+$#input;
for $t (@input) {$t -= $center;}

# find max
my $details = $data->details();
my $max = 1<<($details->{'bits_sample'}-1);
#for $t (@input) {
#	$max = $t  if $t>$max;
#	$max = -$t if -$t>$max;
#}

# infos
print STDERR "Read $name\n";
print STDERR "$seconds secs\n";
print STDERR "$wavFreq Hz\n";
print STDERR "$max MAX\n";

# normalize
#for $t (@input) {$t /= $max;}

# freq thomson
$freq = 2894*2; # vitesse dans le code 

# resample
@t = ();
for($t = 0; $t<=$#input; $t += $wavFreq / $freq) {
	push(@t, $input[int($t)]);
	last if $#t>8000;
}

# sifflement
if(1) {
	$len = 8000;
	@t = ();
	for($t = 0; $t<$len; ++$t) {
		$a = 100.0/(100+$t);
		$p = 3.14159/(1+(0.3*$t)/$len);
		$v = $max*$a*sin($t*$p+3.14159/2);
		$v = $max if $v>$max;
		$v = -$max if $v<-$max;
		push(@t, $v);
	}
}


# sortie
@o = ();
$n = 0;
$v = 0;
$p = 0;
$l = 0;

for $t (@t) {	
	$s = $t<0?-1:1;
	$t = -$t if $s<0;
	$v = int(63*$t/$max);
	if($v>=(31+15)/2) {
		$t = 7;
	} elsif($v>=(15+7)/2) {
		$t = 6;
	} elsif($v>=(7+5)/2) {
		$t = 5;
	} elsif($v>=4) {
		$t = 4;
	} else {
		$t = $v;
	}
	$t = -$t if $s<0;
	$t += 8;
	
	$p = $p*16 + $t;
	if(++$n==4) {
		push(@o, $p);
		$p = $n = 0;
	}
}


$n = 3;
for $t (@o) {
	if(++$n==4) {
		$n = 0;
		print	"\n\tfdb\t";
	} else {
		print	",";
	}
	print sprintf("\$%04X", $t);
}
print "\n";
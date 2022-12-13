#/bin/perl

$B = defined $ENV{'BASE'} ? $ENV{'BASE'} : 10;

# pas de solution à moins de la base 6.
exit unless $B>=6;

print "BASE=$B\n";

# les 36 chiffes possibles (pour l'affichage)
@B = ('0'..'9','A'..'Z');

# auxiliaires
$_100001  = &num(  1,0,0,0,0,1);
$_010010  = &num(  0,1,0,0,1,0);
$_001100  = &num(  0,0,1,1,0,0);
$_1000000 = &num(1,0,0,0,0,0,0);

# on énumère tous les ($a1,$b1,$c1, $a2,$b2,$c2) entre 0 et $B-1 sans
# repetition
@cnt = (0,0,0,0,0,0);

# nombre de solutions
$sol = 0;

# horloge au debut
$time = time;

# enumeration de tous les palindromes potentiels    
do {
	# nouveau sextuplet
	my($a1,$b1,$c1,$a2,$b2,$c2) = &tuple(@cnt);
	
	# les deux nombres palindromes a tester
	$m = $_100001*$a1 + $_010010*$b1 + $_001100*$c1;
	$n = $_100001*$a2 + $_010010*$b2 + $_001100*$c2;
	
	# la somme doit etre un palindrome de 7 lettres
	$s = $m+$n;
	$ok = $s>=$_1000000;
	
	# la somme doit contenir aucun chiffre présent
	$ok = $ok && !&contient_chiffre($s, $a1,$b1,$c1, $a2,$b2,$c2);
	
	# la somme doit etre un palindrome
	$ok = $ok && $s==&rev($s);
	
	# la difference du plus grand et du plus petit...
	$d = $m-$n;
	$ok = $ok && $d>=0;
	
	# ...doit etre un palindrome
	$ok = $ok && $d==&rev($d);
	
	# avec le 3 chiffres de poids faible en ordre croissant
	@t = &mun($d);
	$ok = $ok && $t[0]<=$t[1] && $t[1]<=$t[2];
	
	# si trouve on imprime
	if($ok) {
		print "\n" if ++$sol>1;
		print &str($m),"+",&str($n)," = ",&str($s),"\n";
		print &str($m),"-",&str($n)," = ",&str($d),"\n";
	}

	# prochain tirage
	for($i=$#cnt+1; --$i>=0 && ++$cnt[$i]==$B-$i; $cnt[$i]=0) {}
} while($i>=0);

print "$sol solution(s) en ", time-$time, "s\n";
exit(0);

# sort un n-uplet
sub tuple {
	my(@index) = @_;
	my(@t) = (0..$B-1);
	my(@r);
	while($#index>=0) {push(@r, splice(@t, shift(@index), 1));}
	return @r;
}

# verifie si un nombre contient l'un des chiffrs
sub contient_chiffre {
	my($n, @chiffres) = @_;
	do {
		my $t = $n % $B; 
		for my $c (@chiffres) { return 1 if $c==$t;}
	} while($n=int($n/$B));
	return 0;
}

# convertit un nombre en chaine (base $B)
sub str {
	my $n = $_[0];
	my $s = "";
	do {$s = $B[$n % $B].$s;} while ($n = int($n / $B));
	return $s;
}

# convetit un tableau de chiffres en nombre en base $B
sub num {
	my $n = 0;
	for my $i (@_) {$n = $n*$B + $i;}
	return $n;
}

# operation inverse de num (int-->tableau)
sub mun {
	my $n = $_[0];
	my(@t);
	do {push(@t, $n % $B);} while ($n = int($n / $B));
	return @t;
}

# inverse un nombre en base B
sub rev {
	my $n = $_[0];
	my $t = 0;
	do {
		$t = $t*$B + ($n % $B);
	} while($n = int($n/$B));
	return $t;
}
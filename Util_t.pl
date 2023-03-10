#!/usr/bin/env perl
use strict; use warnings;

use Util;

{
	for (my $n = 0; $n < 4; ++$n)
	{
		my $sx = '';
		my $sy = '';
		{
			for (my $i = 0; $i < $n; ++$i)
			{
				my $sLine = 'xxx';
				$sx .= "\t${sLine}\n"   . "\t\n";
				$sy .= "\t\t${sLine}\n" . "\n";
			}
		}
		
		#printf ("sx:\n{\n%s}\n\n", $sx);
		my $sz = Indent ($sx);
		Azzert ($sz eq $sy);
	}
}

{
	Azzert (ArrayToString ([10, 20, 'xxx']) eq "10\n20\nxxx\n");
}

{
	my $rh = {};
	{
		for (my $i = 0; $i < 100; ++$i)
			{ $$rh {$i} = 2 * $i; }
	}
	
	my $sExpected = "0\n";
	{
		for (my $i = 1; $i < 10; ++$i)
		{
			$sExpected .= "${i}\n";
			for (my $j = 0; $j < 10; ++$j)
			{
				$sExpected .= "${i}${j}\n";
			}
		}
	}
	
	#{0 => 'zero', 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four'};
	#foreach my $ks (keys %$rh)
	#{
	#	printf ("%s\n", $ks);
	#}
	#printf ("[%s]\n", HashMapKeysToString ($rh));
	#Azzert (HashMapKeysToString ({0=>'zero', 1=>'one', 2=>'two', 3=>'three', 4=>'four'}) eq "0\n1\n2\n3\n4\n");
	#printf ("%s\n\n", HashMapKeysToString ($rh));
	#printf ("%s\n\n", $sExpected);
	Azzert (HashMapKeysToString ($rh) eq $sExpected);
}

{
	my $ras = ['zero', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix'];
	Azzert (IndexOfStringInArray ($ras, 'zero') ==  0);
	Azzert (IndexOfStringInArray ($ras, 'neuf') ==  9);
	Azzert (IndexOfStringInArray ($ras, 'ten' ) == -1);
}

printf ("Unit_t.pl: Passed.\n");

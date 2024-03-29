#!/usr/bin/env perl
use strict; use warnings;

use Util;

{
	for (my $bChompLines = 0; $bChompLines < 2; ++$bChompLines)
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
					$sy .= "\t\t${sLine}\n" . (! $bChompLines || $i + 1 < $n ? "\n" : '');
				}
				
				for (my $i = 0; $i < $n; ++$i)
				{
					$sx .= "\t\n";
					if (! $bChompLines)
						{ $sy .= "\n"; }
				}
			}
			
			#printf ("sx:\n{\n%s}\n\n", $sx);
			my $sz = Indent ($sx, 1, $bChompLines);
			
			# [2023-01-16]
			#Azzert ($sz eq $sy);
			if ($sz ne $sy)
			{
				printf ("\$bChompLines %u, \$n %u. \$sz ne \$sy.\n", $bChompLines, $n);
				printf ("\$sx (not indented) with no newline:\n{\n%s}\n\n", $sx);
				printf ("\$sy (not indented) with no newline:\n{\n%s}\n\n", $sy);
				printf ("\$sz (not indented) with no newline:\n{\n%s}\n\n", $sz);
				Azzert (0);
			}
		}
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

{
	my $s0 = "   -g   -std=\"c++17\"  -W'all'   ";
	my @as1 = SplitCommandLine ($s0);
	#printf ("%s\n", ArrayToString (\@as1));
	
	my @as1_Expected = ('-g', '-std=c++17', '-Wall');
	Azzert (scalar (@as1) == scalar (@as1_Expected));
	for (my $i = 0; $i < scalar (@as1); ++$i)
	{
		Azzert ($as1 [$i] eq $as1_Expected [$i]);
	}
}

{
	my %h = ('aaa' => 0x61, 'bbb' => 0x62);
	Azzert (           HashElementOr (\%h, 'aaa', 0xFF) == 0x61);
	Azzert (           HashElementOr (\%h, 'ccc', 0xFF) == 0xFF);
	Azzert (! defined (HashElementOr (\%h, 'zzz'      )));
}

{
	#my $s1 = StringToNumber ('   xxx yyy   ');
	#printf ("\"%s\"\n", $s1);
	
	for (my $iAbsValue = 0; $iAbsValue < 1024; ++$iAbsValue)
	{
		for (my $iSign = 1; $iSign >= -1; $iSign -= 2)
		{
			my $sSign  = $iSign == 1 ? '+' : '-';
			my $iValue = $iSign * $iAbsValue;
			
			for (my $ccSpace = 0; $ccSpace < 3; ++$ccSpace)
			{
				my $sSpace = ' ' x $ccSpace;
				
				{
					my @asArgs = ($sSpace, $sSign, $sSpace, $iAbsValue, $sSpace);
					
					my @asFormats = ('%u', '0x%X', '0x%x', '%Xh', '%xh');
					foreach my $sFormat (@asFormats)
					{
						my $s0 = sprintf ('%s%s%s' . $sFormat . '%s', @asArgs);
						
						my $iResult = StringToNumber ($s0);
						#printf ("iAbsValue %4u. iSign %+d. s0 \"%s\". iResult %d...\n", $iAbsValue, $iSign, $s0, $iResult);
						Azzert (defined ($iResult));
						Azzert ($iResult == $iValue);
					}
				}
			}
		}
	}
	
}

printf ("Unit_t.pl: Passed.\n");

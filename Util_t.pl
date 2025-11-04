#!/usr/bin/env perl
use Mojeom;
use DestroyGuard;
use Util;
use strict; use warnings;

# [2024-07-27] TODO: Somehow test `printf_2s?`.
if (0)
{
	&printf_2s (Util->ERR, "Bau (%s) !\n", 'Hello, World !');
}

{
	&Azzert (  &LooksLikeNumber ('  1024'));
	&Azzert (! &LooksLikeNumber ('  1024q'));
	&Azzert (! &LooksLikeNumber ('Nikita la Femme'));
}

{
	&AzzertSub (sub { return 1; });
	printf ("Expected success: [%u] [%s]\n", defined $@, $@);
	&Azzert ($@ eq '');
	eval { &AzzertSub (sub { return 0; }); };
	printf ("Expected failure: [%u] [%s]\n", defined $@, $@);
	&Azzert ($@ ne '');
	&Azzert ($@ =~ m/\bError: .*\bAzzertion has failed./i);
}

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
			my $sz = &Indent ($sx, 1, $bChompLines);
			
			# [2023-01-16]
			#&Azzert ($sz eq $sy);
			if ($sz ne $sy)
			{
				printf ("\$bChompLines %u, \$n %u. \$sz ne \$sy.\n", $bChompLines, $n);
				printf ("\$sx (not indented) with no newline:\n{\n%s}\n\n", $sx);
				printf ("\$sy (not indented) with no newline:\n{\n%s}\n\n", $sy);
				printf ("\$sz (not indented) with no newline:\n{\n%s}\n\n", $sz);
				&Azzert (0);
			}
		}
	}
}

{
	&Azzert (&ArrayToString ([10, 20, 'xxx']) eq "10\n20\nxxx\n");
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
	#printf ("[%s]\n", &HashMapKeysToString ($rh));
	#&Azzert (&HashMapKeysToString ({0=>'zero', 1=>'one', 2=>'two', 3=>'three', 4=>'four'}) eq "0\n1\n2\n3\n4\n");
	#printf ("%s\n\n", &HashMapKeysToString ($rh));
	#printf ("%s\n\n", $sExpected);
	&Azzert (&HashMapKeysToString ($rh) eq $sExpected);
}

{
	my %h = (0 => '000', 'aaa' => 'AAA');
	#printf ("%s\n", &HashToString (\%h));
	&Azzert_eq (&HashToString (\%h), "'0' -> '000'\n" . "'aaa' -> 'AAA'\n");
}

{
	my $ras = ['zero', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix'];
	&Azzert (&IndexOfStringInArray ($ras, 'zero') ==  0);
	&Azzert (&IndexOfStringInArray ($ras, 'neuf') ==  9);
	&Azzert (&IndexOfStringInArray ($ras, 'ten' ) == -1);
}

{
	my $s0 = "   -g   -std=\"c++17\"  -W'all'   ";
	my @as1 = &SplitCommandLine ($s0);
	#printf ("%s\n", &ArrayToString (\@as1));
	
	my @as1_Expected = ('-g', '-std=c++17', '-Wall');
	&Azzert (scalar (@as1) == scalar (@as1_Expected));
	for (my $i = 0; $i < scalar (@as1); ++$i)
	{
		&Azzert ($as1 [$i] eq $as1_Expected [$i]);
	}
}

{
	my %h = ('aaa' => 0x61, 'bbb' => 0x62);
	&Azzert (           &HashElementOr (\%h, 'aaa', 0xFF) == 0x61);
	&Azzert (           &HashElementOr (\%h, 'ccc', 0xFF) == 0xFF);
	&Azzert (! defined (&HashElementOr (\%h, 'zzz'      )));
}

# [2024-08-15 :x:x] https://youtu.be/yokGq0yKdUc
my $sAlternate = 'T800 is re-routing to Alternate Power...';

# [2024-08-15 :x:x]
#   `&ArrayElement(Or|OrSub|OrAzzert)`:
{
	my $fFactor = 11;
	my @a = map { $fFactor * $_; } 0 .. 9;
	
	{
		for (my $i = -1; $i <= scalar @a; ++$i)
		{
			my $iAdjusted = $i >= 0 ? $i : scalar @a + $i;
			my $bGood = $iAdjusted >= 0 && $iAdjusted < scalar @a;
			
			{
				my $y = &ArrayElementOr (\@a, $i, $sAlternate);
				if ($bGood)
				{
					&Azzert_num_eq ($y, $a [$i]);
				}
				else
				{
					&Azzert_str_eq ($y, $sAlternate);
				}
			}
			
			{
				my $y = &ArrayElementOrSub (\@a, $i, sub { my ($ra, $ki, $x) = @_; return $ki + $x; }, 7);
				if ($bGood)
				{
					&Azzert_num_eq ($y, $a [$i]);
				}
				else
				{
					&Azzert_num_eq ($y, $i + 7);
				}
			}
			
			{
				my $y;
				my $sMessage = sprintf ('Failure at %u !!', $i);
				eval
				{
					$y = &ArrayElementOrAzzert (\@a, $i, $sMessage);
				};
				
				if ($bGood)
				{
					&Azzert_str_eq ($@, '');
					&Azzert_num_eq ($y, $a [$i]);
				}
				else
				{
					&Azzert_str_ne ($@, '');
					&Azzert_num_ge (index ($@, $sMessage), 0);
				}
			}
		}
	}
	{
		my %h = map { ("key_${_}", "data_${_}"); } @a;
		
		#printf ("%s\n", &IndentWithTitle (&HashToString (\%h), '%h:'));
		
		for (my $i = -1; $i <= scalar @a; ++$i)
		{
			my $iAdjusted = $i >= 0 ? $i : scalar @a + $i;
			my $bGood = $iAdjusted >= 0 && $iAdjusted < scalar @a;
			
			my $j = &ArrayElementOr (\@a, $i, -927);
			my ($ks, $ds) = ("key_${j}", "data_${j}");
			
			{
				my $y = &HashElementOr (\%h, $ks, $sAlternate);
				if ($bGood)
				{
					&Azzert_str_eq ($y, $ds);
				}
				else
				{
					&Azzert_str_eq ($y, $sAlternate);
				}
			}
			
			{
				my $y = &HashElementOrSub (\%h, $ks, sub { my ($rh, $ks, $x) = @_; return $ks . $x; }, ' Tashi');
				if ($bGood)
				{
					&Azzert_str_eq ($y, $ds);
				}
				else
				{
					&Azzert_str_eq ($y, $ks . ' Tashi');
				}
			}
			
			{
				my $y;
				my $sMessage = sprintf ('Failure at %u !!', $i);
				eval
				{
					$y = &ArrayElementOrAzzert (\@a, $i, $sMessage);
				};
				
				if ($bGood)
				{
					&Azzert_str_eq ($@, '');
					&Azzert_num_eq ($y, $a [$i]);
				}
				else
				{
					&Azzert_str_ne ($@, '');
					&Azzert_num_ge (index ($@, $sMessage), 0);
				}
			}
			
			{
				my $y;
				my $sMessage = sprintf ('Failure at %u !!', $i);
				eval
				{
					$y = &HashElementOrAzzert (\%h, $ks, $sMessage);
				};
				
				if ($bGood)
				{
					&Azzert_str_eq ($@, '');
					&Azzert_str_eq ($y, $ds);
				}
				else
				{
					&Azzert_str_ne ($@, '');
					&Azzert_num_ge (index ($@, $sMessage), 0);
				}
			}
		}
	}
}

{
	#my $s1 = &StringToNumber ('   xxx yyy   ');
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
					
					my @asFormats = ('%u', '0X%X', '0x%x', '%XH', '%xh');
					foreach my $sFormat (@asFormats)
					{
						my $s0 = sprintf ('%s%s%s' . $sFormat . '%s', @asArgs);
						
						my $iResult = &StringToNumber ($s0);
						#printf ("iAbsValue %4u. iSign %+d. s0 %-16s. iResult %+16d...\n", $iAbsValue, $iSign, "'${s0}'", $iResult);
						&Azzert (defined ($iResult));
						&Azzert ($iResult == $iValue);
					}
				}
			}
		}
	}
	
}

{
	my $mojeom = Mojeom->CreateObject ();
	printf ("Mojeom {%s}.\n", $mojeom->ToString ());
	$mojeom->R (1.1); &Azzert ($mojeom->R () == 1);
	$mojeom->R (0.5); &Azzert ($mojeom->R () == 0.5);
	
	# [2024-08-12] We test a call to `GetOrCheckSetObjectProperty` without a checker sub.
	{
		my $a0 = $mojeom->A ();
		my $a1 = $a0 - 0.25;
		$mojeom->A ($a1);
		&Azzert_num_eq ($mojeom->A (), $a1);
	}
	
	# [2024-08-14 >:D<] We test `GetOrAlterSetObjectProperty`:
	{
		$mojeom->B ( 0.5 )             ; &Azzert ($mojeom->B () ==  0.5 );
		$mojeom->B ('Ares vs Tashi !!'); &Azzert ($mojeom->B () ==  0.5 );
		$mojeom->B (-0.25)             ; &Azzert ($mojeom->B () ==  0   );
		$mojeom->B ( 1.25)             ; &Azzert ($mojeom->B () ==  1   );
	}
	
	# [2024-08-14 >:D<] We test `GetOrDefAlterSetObjectProperty`:
	{
		$mojeom->G (undef); &Azzert ($mojeom->G () == 0.927);
		$mojeom->G ('S7 aka Sophie !!'); &Azzert ($mojeom->G () ==  0.927);
		$mojeom->G (-0.25 )            ; &Azzert ($mojeom->G () ==  0    );
		$mojeom->G ( 1.25 )            ; &Azzert ($mojeom->G () ==  1    );
	}
}

{
	my ($x, $y) = (10, 13);
	&Azzert_num_eq ($x, $x);
	&Azzert_num_ne ($x, $y);
	&Azzert_num_lt ($x, $y); &Azzert_num_le ($x, $x); &Azzert_num_le ($x, $y);
	&Azzert_num_gt ($y, $x); &Azzert_num_ge ($y, $y); &Azzert_num_ge ($y, $x);
}

{
	my ($x, $y) = (' 10', 'Abracadabra');
	&Azzert_str_ne ($x, $y);
	&Azzert_str_lt ($x, $y);
	&Azzert_gt     ($y, $x, 'This must be it !');
}

# `(Shift|Pop)(|Or|OrInvoke|OrAzzert)`:
{
	my $iVerb = 0;
	
	my $fFactor = 11;
	my @af0 = map { $_ * $fFactor } 0 .. 9;
	my $n = scalar @af0;
	
	for (my $iRep = 0; $iRep < 6; ++$iRep)
	{
		my @af1 = @af0;
		for (my $i = 0; $i < $n + 2; ++$i)
		{
			my $g0;
			if ($iVerb)
			{
				printf ("iRep %u, i %2u, n %2u.\n{\n", $iRep, $i, $n);
				my $g0 = DestroyGuard->CreateObject (sub { printf ("}\n\n"); });
				
				printf ("af1 (%s).\n", join (' ', @af1));
			}
			
			use List::Util qw (max);
			&Azzert_num_eq (scalar @af1, max ($n - $i, 0));
			
			my $y =
				sub
				{
					if    ($iRep == 0)
					{
						return &ShiftOr (\@af1, $sAlternate);
					}
					elsif ($iRep == 1)
					{
						return &PopOr   (\@af1, $sAlternate);
					}
					elsif ($iRep == 2)
					{
						return &ShiftOrInvoke (\@af1, sub { return $sAlternate; });
					}
					elsif ($iRep == 3)
					{
						return &PopOrInvoke   (\@af1, sub { return $sAlternate; });
					}
					elsif ($iRep == 4 || $iRep == 5)
					{
						my $sMsgError = sprintf ('Failure at %u !', $i);
						
						my $yy = eval
						{
							return
								$iRep == 4 ?
									&ShiftOrAzzert (\@af1, $sMsgError)
									:
									&PopOrAzzert   (\@af1, $sMsgError);
						};
						
						if ($i < $n)
						{
							&Azzert_str_eq ($@, '');
							return $yy;
						}
						else
						{
							&Azzert_str_ne ($@, '');
							&Azzert (index ($@, $sMsgError) >= 0);
							return $sAlternate;
						}
					}
					else
					{
						&Azzert ();
					}
				}->();
			
			if ($i < $n)
			{
				&Azzert_num_eq ($y, (! ($iRep % 2) ? $i : $n - 1 - $i) * $fFactor);
			}
			else
			{
				&Azzert_str_eq ($y, $sAlternate);
			}
		}
	}
	
	for (my $iRep = 0; $iRep < 3; ++$iRep)
	{
		if ($iVerb) { printf ("af0     (%s).\n", join (' ', @af0)); }
		my @afAlternate = (@af0, 1000 .. 1019);
		
		for (my $i = 0; $i < scalar @afAlternate; ++$i)
		{
			my @af1 = @af0;
			my @afResult =
				sub
				{
					if    ($iRep == 0)
					{
						return &ShiftNOr (\@af1, $i, \@afAlternate);
					}
					elsif ($iRep == 1)
					{
						return &ShiftNOrInvoke (\@af1, $i, sub { return \@afAlternate; });
					}
					elsif ($iRep == 2)
					{
						my $sMessage = sprintf ('Failure at %u !', $i);
						my @yy = eval
						{
							return &ShiftNOrAzzert (\@af1, $i, $sMessage);
						};
						
						if ($i <= scalar @af0)
						{
							&Azzert_str_eq ($@, '');
							return @yy;
						}
						else
						{
							&Azzert_str_ne ($@, '');
							&Azzert_num_ge (index ($@, $sMessage), 0);
							return &ShiftNOr (\@af1, $i, \@afAlternate);
						}
					}
					else
					{
						&Azzert ();
					}
				}->();
			
			if ($iVerb)
			{
				printf ("af1      (%s).\n", join (' ', @af1     ));
				printf ("afResult (%s).\n", join (' ', @afResult));
			}
			
			&Azzert_num_eq (scalar (@afResult), $i);
			
			for (my $k = 0; $k < scalar (@afResult); ++$k)
			{
				if ($iVerb >= 2) { printf ("k %2u.\n", $k); }
				if ($k < scalar @af1)
				{
					&Azzert_num_eq ($afResult [$k], $af0         [$k]);
				}
				else
				{
					&Azzert_num_eq ($afResult [$k], $afAlternate [$k]);
				}
			}
			
			if ($iVerb) { printf ("\n"); }
		}
	}
}

sub CheckParams
{
	my $x = &ShiftOrAzzert (\@_); &Azzert ($x == 10);
	my $y = &ShiftOrAzzert (\@_); &Azzert ($y == 20);
	# [2024-08-08] TODO: Find a way to test this !!
	#my $z = &ShiftOrAzzert (\@_);
	# [2024-08-19] Here we go, using `eval` and `$@` !!
	my $z;
	{
		&Azzert (! @_);
		
		#printf ("\$\@ %s.\n", "'${@}'");
		eval
		{
			$z = &ShiftOrAzzert (\@_);
		};
		
		#printf ("\$\@ %s.\n", "'${@}'");
		
		&Azzert (length $@);
		&Azzert ($@ =~ m/\bShiftOrAzzert\b/);
	}
	
	&Azzert (! defined ($z));
}
&CheckParams (10, 20);

sub QuoteArg_unittest
{
	&Azzert_eq (&QuoteArg ('aaa'), 'aaa');
	&Azzert_eq (&QuoteArg ('aaa "bbb ccc"'), "'aaa \"bbb ccc\"'");
	&Azzert_eq (&QuoteArg ("aaa 'bbb ccc' \"ddd eee\""), "'aaa '\\''bbb ccc'\\'' \"ddd eee\"'");
	
	&Azzert_str_eq
	(
		&QuoteArgs
		(
		[
			'xxx',
			'yyy',
			'',
			'zzz zzz',
			"zzz\tzzz",
			'ttt',
			"Apostrophe's",
			'Wonder Woman !!',
			'`Back-Ticks...`',
			'Mysterio ??',
			'"Lemme Quote You..."'
		]
		),
		
		"xxx yyy '' 'zzz zzz' 'zzz\tzzz' ttt " .
		"'Apostrophe'\\''s'" .
		" 'Wonder Woman !!' '\`Back-Ticks...\`' 'Mysterio ??' '\"Lemme Quote You...\"'"
	);
}
&QuoteArg_unittest ();

sub QuoteArgs_unittest
{
	&Azzert_str_eq (&QuoteArgs (['aaa bbb', 'ccc', '', 'ddd eee']), "'aaa bbb' ccc '' 'ddd eee'");
}
&QuoteArgs_unittest ();

printf ("Unit_t.pl: Passed.\n");

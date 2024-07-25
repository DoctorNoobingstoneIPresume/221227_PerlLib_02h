#!/usr/bin/env perl
use DestroyGuard;
use Util;
use strict; use warnings;

sub Main
{
	my $x = 0;
	my $y = 0;
	
	{
		my $gy = DestroyGuard->CreateObject ();
		$gy->OnDestroy (sub { $y = 2; });
		printf ("y %u.\n", $y);
		&Azzert (! $y);
		
		{
			my $gx = DestroyGuard->CreateObject (sub { $x = 1; });
			printf ("x %u.\n", $x);
			&Azzert (! $x);
		}
		
		printf ("x %u.\n", $x);
		&Azzert ($x == 1);
	}
	
	printf ("y %u.\n", $y);
	&Azzert ($y == 2);
}

&Main (@ARGV);

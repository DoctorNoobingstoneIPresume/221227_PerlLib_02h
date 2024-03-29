# [2022-11-03] Stolen from "F:/Adder1F/Projects/2022/221027_Output_of_readelf_01h/221027_ElfAnalyzer_PerlEdition/Util.pm":

package Util;
use Exporter qw (import);
our @EXPORT = qw
(
	Azzert Azzert_eq Azzert_ne
	IndentPrefix Indent IndentWithTitle ArrayToString HashMapKeysToString IndexOfStringInArray
	SplitCommandLine HashElementOr StringToNumber
	GetOrSetObjectProperty
	PrettyIntegral
);

sub Azzert
{
	my $bCondition = shift;
	my $sMessage   = @_ ? shift : 'No message.';
	
	if (! $bCondition)
	{
		{ use IO::Handle; STDOUT->flush (); }
		{ use Carp; croak ("Azzertion has failed. ${sMessage}"); }
	}
	
	return $bCondition;
}

sub Azzert_eq { my $s0 = @_ ? shift : Azzert (); my $s1 = @_ ? shift : Azzert (); Azzert ($s0 eq $s1, "Azzert_eq has failed: '${s0}' vs '${s1}'."); }
sub Azzert_ne { my $s0 = @_ ? shift : Azzert (); my $s1 = @_ ? shift : Azzert (); Azzert ($s0 ne $s1, "Azzert_ne has failed: '${s0}' vs '${s1}'."); }

sub IndentPrefix
{
	my $n = @_ ? shift : 1;
	
	# [2022-11-03]
	return "\t" x $n;
	#return "  " x $n;
}

sub Indent
{
	my $sx          = @_ ? shift : Azzert ();
	my $n           = @_ ? shift : 1;
	my $bChompLines = @_ ? shift : 1;
	
	my $sy = '';
	{
		my $sLinePrefix = IndentPrefix ($n);
		
		my $nEmptyLines = 0;
		my $sBuffered   = '';
		my $bAnything   = 0;
		
		my $nc = length ($sx);
		for (my $ic = 0; $ic <= $nc; ++$ic)
		{
			if ($bAnything)
				{ Azzert (! length ($sBuffered)); }
			
			my $c   = $ic < $nc ? substr ($sx, $ic, 1) : '';
			my $cod = $ic < $nc ? ord ($c)             : 0 ;
			
			if ($cod == 0xA || ! $cod)
			{
				if ($cod == 0xA)
				{
					if (! $bChompLines)
						{ $sy .= $c; }
					else
					{
						if ($bAnything)
							{ $sy .= $c; $nEmptyLines = 0; }
						else
							{ ++$nEmptyLines; }
					}
				}
				
				$sBuffered = '';
				$bAnything = 0;
			}
			elsif ($cod <= 0x20)
			{
				($bAnything ? $sy : $sBuffered) .= $c;
			}
			else
			{
				if ($bAnything)
					{ $sy .= $c; }
				else
				{
					$sy .= "\n" x $nEmptyLines . $sLinePrefix . $sBuffered . $c;
					$nEmptyLines = 0;
					$sBuffered   = '';
					$bAnything   = 1;
				}
			}
		}
	}
	
	return $sy;
}

sub IndentWithTitle
{
	my $sx          = @_ ? shift : Azzert ();
	my $sTitle      = @_ ? shift : 'Untitled';
	my $n           = @_ ? shift : 1;
	my $bChompLines = @_ ? shift : 1;
	
	return sprintf ("%s\n{\n%s}\n\n", $sTitle, Indent ($sx, $n, $bChompLines));
}

sub ArrayToString
{
	my $ras = @_ ? shift : Azzert ();
		{ Azzert (ref $ras eq 'ARRAY'); }
	
	my $sRet = '';
	{
		foreach my $s (@$ras)
		{
			$sRet .= $s . "\n";
		}
	}
	
	return $sRet;
}

sub HashMapKeysToString
{
	my $rhks = @_ ? shift : Azzert ();
		{ Azzert (ref $rhks eq 'HASH'); }
	
	my $sRet = '';
	{
		foreach my $ks (sort keys %$rhks)
		{
			$sRet .= $ks . "\n";
		}
	}
	
	return $sRet;
}

sub IndexOfStringInArray
{
	my $rasHaystack = @_ ? shift : Azzert ();
		{ Azzert (ref $rasHaystack eq 'ARRAY'); }
	my $sNeedle     = @_ ? shift : Azzert ();
	
	my $i = 0;
	foreach my $sHaystack (@$rasHaystack)
	{
		if ($sHaystack eq $sNeedle)
			{ return $i; }
		
		++$i;
	}
	
	return -1;
}

sub SplitCommandLine
{
	my $s0 = @_ ? shift : Azzert ();
	
	my @asRet = ();
	{
		my $iState = 0;
		my $sArg   = '';
		my $cc0    = length ($s0);
		for (my $ic0 = 0; $ic0 <= $cc0; ++$ic0) # Yes, <=.
		{
			my $c0   = $ic0 < $cc0 ? substr ($s0, $ic0, 1) : '';
			my $ord0 = $ic0 < $cc0 ? ord ($c0)             : 0;
			
			if (! $iState)
			{
				if (! $ord0)
					{ last; }
				elsif ($ord0 <= 0x20)
					{ next; }
				elsif ($c0 eq "\"")
					{ $iState = 20; }
				elsif ($c0 eq "\'")
					{ $iState = 30; }
				else
					{ $sArg .= $c0; $iState = 10; }
			}
			elsif ($iState == 10)
			{
				Azzert (length ($sArg));
				
				if (! $ord0)
					{ push (@asRet, $sArg); $sArg = ''; last; }
				elsif ($ord0 <= 0x20)
					{ push (@asRet, $sArg); $sArg = ''; $iState = 0; }
				elsif ($c0 eq "\"")
					{ $iState = 20; }
				elsif ($c0 eq "\'")
					{ $iState = 30; }
				else
					{ $sArg .= $c0; }
			}
			elsif ($iState == 20)
			{
				if (! $ord0)
					{ push (@asRet, $sArg); $sArg = ''; last; }
				elsif ($c0 eq "\\")
					{ $iState = 21; }
				elsif ($c0 eq "\"")
					{ $iState = 10; }
				else
					{ $sArg .= $c0; }
			}
			elsif ($iState == 21)
			{
				if (! $ord0)
					{ push (@asRet, $sArg); $sArg = ''; last; }
				else
					{ $sArg .= $c0; $iState = 20; }
			}
			elsif ($iState == 30)
			{
				if (! $ord0)
					{ push (@asRet, $sArg); $sArg = ''; last; }
				elsif ($c0 eq '\'')
					{ $iState = 10; }
				else
					{ $sArg .= $c0; }
			}
			else
			{
				Azzert ();
			}
		}
	}
	
	return @asRet;
}

sub HashElementOr
{
	my $rh           = @_ ? shift : Azzert ();
	my $ks           = @_ ? shift : Azzert ();
	my $sAlternative = @_ ? shift : undef;
	
	return exists $rh->{$ks} ? $rh->{$ks} : $sAlternative;
}

sub StringToNumber
{
	my $s0    = @_ ? shift : Azzert ();
	my $iBase = @_ ? shift : 10;
	
	$s0 =~ s#^ \s* (\S.*?) \s* $#$1#x;
	
	my $iSign = +1;
	{
		if ($s0 =~ m# ([+-]) (.*) #x)
			{ $iSign = $1 eq '+' ? +1 : -1; $s0 = $2; }
	}
	
	my $s1 = '';
	{
		if    ($s0 =~ m# 0[xX] ([0-9A-Fa-f][0-9A-Fa-f_']*) #x)
			{ $iBase = 16; $s1 = $1; }
		elsif ($s0 =~ m#       ([0-9A-FA-f][0-9A-Fa-f_']*)[Hh] #x)
			{ $iBase = 16; $s1 = $1; }
		elsif ($s0 =~ m# ([0-9_']+) #x)
			{ $iBase = 10; $s1 = $1; }
		else
			{ return undef; }
	}
	
	$iValue = 0;
	{
		my $sUpperCaseDigits = '0123456789ABCDEF';
		my $sLowerCaseDigits = '0123456789abcdef';
		
		#printf ("s1 \"%s\".\n", $s1);
		
		my $cc = length ($s1);
		for ($ic = 0; $ic < $cc; ++$ic)
		{
			my $c     = substr ($s1, $ic, 1);
			my $digit = index ($sUpperCaseDigits, $c);
			{
				if ($digit < 0)
					{ $digit = index ($sLowerCaseDigits, $c); }
			}
			
			if ($digit < 0)
				{ next; }
			
			if ($digit >= $iBase)
				{ return undef; }
			
			$iValue = $iValue * $iBase + $digit;
		}
	}
	
	return $iSign * $iValue;
}

sub GetOrSetObjectProperty
{
	my $sProperty = @_ ? shift : Azzert ();
	my $self      = @_ ? shift : Azzert ();
	
	if (@_) { my $value = shift; $self->{$sProperty} = $value; return $self; }
	else    { return $self->{$sProperty}; }
}

# https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
sub PrettyIntegral
{
	my $x             = @_ ? shift : Azzert ();
	my $Width_nDigits = @_ ? shift : 0;
	
	while ($x =~ s#(\d+)(\d{3})#$1,$2#g) {}
	if ($Width_nDigits >= 1)
	{
		$x = sprintf ("%*s", $Width_nDigits + int (($Width_nDigits - 1) / 3), $x);
	}
	
	return $x;
}

1;

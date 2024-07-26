# [2022-11-03] Stolen from "F:/Adder1F/Projects/2022/221027_Output_of_readelf_01h/221027_ElfAnalyzer_PerlEdition/Util.pm":

package Util;
use Exporter qw (import);
our @EXPORT = qw
(
	printf_2 SeverityText printf_2s
	EMERG PANIC ALERT CRIT ERR ERROR WARNING WARN NOTICE INFO DEBUG SEVERITY_LEVEL
	Azzert Azzert_eq Azzert_ne
	Azzert_num_Impl Azzert_num_eq Azzert_num_ne Azzert_num_lt Azzert_num_le Azzert_num_gt Azzert_num_ge
	IndentPrefix Indent IndentWithTitle ArrayToString HashMapKeysToString HashToString IndexOfStringInArray
	SplitCommandLine HashElementOr StringToNumber
	GetOrSetObjectProperty GetOrCheckSetObjectProperty
	PrettyIntegral
	QuoteArg QuoteArgs
);

sub printf_2
{
	{ use IO::Handle; STDOUT->flush (); }
	return printf STDERR (@_);
}

# [2024-07-25] https://en.wikipedia.org/wiki/Syslog
use constant
{
	EMERG   => 0, PANIC   => 0,
	ALERT   => 1,
	CRIT    => 2,
	ERR     => 3, ERROR   => 3,
	WARNING => 4, WARN    => 4,
	NOTICE  => 5,
	INFO    => 6,
	DEBUG   => 7,
	
	SEVERITY_LIMIT => 8
};

# [2024-07-25]
#   We might propose the (deprecated) 'error' text instead of the 'err' text
#   in order to allow the human user to search for '(warning|error):' within output of tools...
use constant SEVERITY_TEXT        => qw (emerg alert crit err warning notice info debug);
use constant SEVERITY_TEXT_MAXLEN => 7;

sub SeverityText
{
	my $iSeverity = @_ ? shift : Azzert ();
	{
		Azzert ($iSeverity >= 0 && $iSeverity < SEVERITY_LIMIT);
	}
	
	return (SEVERITY_TEXT) [$iSeverity];
}

sub printf_2s
{
	my $iSeverity = @_ ? shift : Azzert ();
	my $sSeverity = SeverityText ($iSeverity);
	
	{ use IO::Handle; STDOUT->flush (); }
	printf STDERR ('[%-*s] ', SEVERITY_TEXT_MAXLEN + 1, $sSeverity . ':');
	printf STDERR (@_);
}

sub Azzert
{
	my $bCondition = shift;
	my $sMessage   = @_ ? shift : 'No message.';
	
	if (! $bCondition)
	{
		{ use IO::Handle; STDOUT->flush (); }
		{ use Carp; croak ("Error: Azzertion has failed. ${sMessage}"); }
	}
	
	return $bCondition;
}

sub Azzert_eq { my $s0 = @_ ? shift : Azzert (); my $s1 = @_ ? shift : Azzert (); Azzert ($s0 eq $s1, "Azzert_eq has failed: '${s0}' vs '${s1}'."); }
sub Azzert_ne { my $s0 = @_ ? shift : Azzert (); my $s1 = @_ ? shift : Azzert (); Azzert ($s0 ne $s1, "Azzert_ne has failed: '${s0}' vs '${s1}'."); }

sub Azzert_num_Impl
{
	my $rFunction     = @_ ? shift : &Azzert (); { &Azzert (ref $rFunction eq 'CODE'); }
	my $x             = @_ ? shift : &Azzert ();
	my $y             = @_ ? shift : &Azzert ();
	# [2024-07-26] https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my $sFunctionName = @_ ? shift : (caller (1)) [3];
	&Azzert (! @_);
	
	my $bResult = $rFunction->($x, $y);
	if (! $bResult)
	{
		my $sMessage = sprintf ('%s has failed (%g vs %g) !', "'${sFunctionName}'", $x, $y);
		Azzert (0, $sMessage);
	}
}

sub Azzert_num_eq { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x == $y; }, splice (@_, 0, 2)); }
sub Azzert_num_ne { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x != $y; }, splice (@_, 0, 2)); }
sub Azzert_num_lt { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x <  $y; }, splice (@_, 0, 2)); }
sub Azzert_num_le { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x <= $y; }, splice (@_, 0, 2)); }
sub Azzert_num_gt { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x >  $y; }, splice (@_, 0, 2)); }
sub Azzert_num_ge { return &Azzert_num_Impl (sub { my ($x, $y) = @_; return $x >= $y; }, splice (@_, 0, 2)); }

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

sub HashToString
{
	my $rh = @_ ? shift : Azzert ();
		{ Azzert (ref $rh eq 'HASH'); }
	my $ccKey = @_ ? shift : 0;
		{ Azzert (ref $ccKey eq ''); }
	
	my $sRet = '';
	{
		foreach my $ks (sort keys %$rh)
		{
			$sRet .= sprintf ("%-*s -> %s\n", $ccKey, "'" . $ks . "'", "'" . $rh->{$ks} . "'");
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

sub GetOrCheckSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq ref '');
	my $rfnCheck  = @_ ? shift : &Azzert (); if (defined ($rfnCheck)) { &Azzert (ref $rfnCheck eq ref sub {}); }
	my $self      = @_ ? shift : &Azzert ();
	
	if (@_)
	{
		my $value = shift;
		
		if (defined ($rfnCheck))
		{
			my $bResult = & {$rfnCheck} ($value);
			# [2024-07-26] TODO:
			#   Should we warn or silently reject or loudly reject ?!
			#   Currently, we let the Client decide, e.g. by writing `if (! ...) { return 0; } return 1;` or `&Azzert (...); return 1;`.
			#&Azzert ($bResult);
			if ($bResult)
			{
				$self->{$sProperty} = $value;
			}
		}
		
		return $self;
	}
	else
	{
		return $self->{$sProperty};
	}
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

sub QuoteArg
{
	my $sArg = @_ ? shift : Azzert ();
	
	if ($sArg =~ m#'#)
	{
		$sArg =~ s#\\#\\\\#g;
		$sArg =~ s#"#\\"#g;
		#$sArg =~ s#'#\\'#g;
		$sArg = "\"${sArg}\"";
	}
	elsif (! length ($sArg) || $sArg =~ m#\s#)
	{
		$sArg = "'${sArg}'";
	}
	else
	{}
	
	return $sArg;
}

sub QuoteArgs
{
	my $rasArgs = @_ ? shift : Azzert (); { Azzert (ref $rasArgs eq 'ARRAY'); }
	
	my $sRet = '';
	{
		my $sSep = '';
		foreach my $sArg (@$rasArgs)
		{
			$sRet .= $sSep . QuoteArg ($sArg);
			$sSep = ' ';
		}
	}
	
	return $sRet;
}

1;

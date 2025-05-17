# [2022-11-03] Stolen from "F:/Adder1F/Projects/2022/221027_Output_of_readelf_01h/221027_ElfAnalyzer_PerlEdition/Util.pm":

package Util;

use Exporter qw (import);
our @EXPORT = qw
(
	LooksLikeNumber
	printf_2 SeverityText printf_2s
	EMERG PANIC ALERT CRIT ERR ERROR WARNING WARN NOTICE INFO DEBUG SEVERITY_LEVEL
	Die Croak Warn
	Azzert
	AzzertSub
	Azzert_Compare_Impl
	Azzert_num_eq Azzert_num_ne Azzert_num_lt Azzert_num_le Azzert_num_gt Azzert_num_ge
	Azzert_str_eq Azzert_str_ne Azzert_str_lt Azzert_str_le Azzert_str_gt Azzert_str_ge
	Azzert_eq     Azzert_ne     Azzert_lt     Azzert_le     Azzert_gt     Azzert_ge
	
	Shift  ShiftOr  ShiftOrInvoke  ShiftOrAzzert
	Pop    PopOr    PopOrInvoke    PopOrAzzert
	ShiftN ShiftNOr ShiftNOrInvoke ShiftNOrAzzert
	
	IndentPrefix Indent IndentWithTitle ArrayToString HashMapKeysToString HashToString IndexOfStringInArray
	SplitCommandLine
	
	ArrayElement ArrayElementOr ArrayElementOrInvoke ArrayElementOrAzzert ArrayElementMust ArrayElementOrSub
	HashElement  HashElementOr  HashElementOrInvoke  HashElementOrAzzert  HashElementMust  HashElementOrSub
	
	StringToNumber
	IsHashOrObject
	GetOrSetObjectProperty GetOrCheckSetObjectProperty GetOrAlterSetObjectProperty GetOrDefAlterSetObjectProperty
	PrettyIntegral
	QuoteArg QuoteArgs
);

use strict; use warnings;

# [2024-08-15 :x:x]
#   LooksLikeNumber:
#   
#   Our `LooksLikeNumber` simply forwards the call to `Scalar::Util::looks_like_number`.
#   
#   `Scalar::Util` does not export anything by default.
#   
#   Therefore we have to either explicitly write (at the top of the file):
#   `use Scalar::Util qw (looks_like_number);`
#   and then write (at each call site):
#   `&Azzert (looks_like_number ($x));`,
#   or write (at each call site) (if we want to reduce the scope):
#   `&Azzert (sub { use Scalar::Util qw (looks_like_number); return looks_like_number ($x); }->());`.
#   
#   Our new `LooksLikeNumber` is exported by default by this package,
#   so we can just write (at the top of the file):
#   `use Util;`
#   and then write (at each call site):
#   `&Azzert (LooksLikeNumber (&x));`.
#
sub LooksLikeNumber
{
	use Scalar::Util qw (looks_like_number);
	return &looks_like_number (@_);
}

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
# [2024-07-29]
#   Here we go (switching from 'err' to 'error'):
use constant SEVERITY_TEXT        => qw (emerg alert crit error warning notice info debug);
use constant SEVERITY_TEXT_MAXLEN => 7;

sub SeverityText
{
	my $iSeverity = @_ ? shift : &Azzert ();
	{
		&Azzert ($iSeverity >= 0 && $iSeverity < SEVERITY_LIMIT);
	}
	
	return (SEVERITY_TEXT) [$iSeverity];
}

sub printf_2s
{
	my $iSeverity = @_ ? shift : &Azzert ();
	my $sSeverity = SeverityText ($iSeverity);
	
	{ use IO::Handle; STDOUT->flush (); }
	printf STDERR ('[%-*s] ', SEVERITY_TEXT_MAXLEN + 1, $sSeverity . ':');
	printf STDERR (@_);
}

sub Die
{
	{ use IO::Handle; STDOUT->flush (); }
	die (@_);
}

sub Croak
{
	{ use IO::Handle; STDOUT->flush (); }
	{ use Carp; croak (@_); }
}

sub Warn
{
	{ use IO::Handle; STDOUT->flush (); }
	warn (@_);
}

sub Azzert
{
	my $bCondition = shift;
	my $sMessage   = shift;
		{ if (! defined ($sMessage)) { $sMessage = 'No message.'; } }
	
	if (! $bCondition)
	{
		&Croak ("Error: Azzertion has failed. ${sMessage}");
	}
	
	return $bCondition;
}

sub AzzertSub
{
	my $rfn      = @_ ? shift : &Azzert ();
	my $sMessage =      shift;
	
	my $bResult  = $rfn->(@_);
	&Azzert ($bResult, $sMessage);
}

sub Azzert_Compare_Impl
{
	my $rFunction     = @_ ? shift : &Azzert (); { &Azzert (ref $rFunction eq 'CODE'); }
	my $x             = @_ ? shift : &Azzert ();
	my $y             = @_ ? shift : &Azzert ();
	my $sMessage      =      shift;
	# [2024-07-26] https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	my $sFunctionName = @_ ? shift : (caller (1)) [3];
	&Azzert (! @_);
	
	my $bResult;
	{
		local ($a, $b) = ($x, $y);
		# [2025-05-04] TODO:
		#   Currently, we make the arguments available to the callee
		#   both as the first two positional parameters and as the `$a` and `$b` named variables.
		#   However, in the future, we are only going to the support the latter approach (named variables).
		$bResult = $rFunction->($x, $y);
	}
	
	if (! $bResult)
	{
		my $sMessage = sprintf
		(
			'%s has failed (%s vs %s) !%s',
			"'${sFunctionName}'", "'${x}'", "'${y}'", defined ($sMessage) ? " ${sMessage}" : ''
		);
		
		&Azzert (0, $sMessage);
	}
	
	return $bResult;
}

# [2024-07-29] `Azzert_(num|str|)_(eq|ne|lt|le|gt|ge)`:
#   TODO: Could we "generate" the Perl code with less repetition ? :)

sub Azzert_num_eq { return &Azzert_Compare_Impl (sub { return $a == $b; }, @_); }
sub Azzert_num_ne { return &Azzert_Compare_Impl (sub { return $a != $b; }, @_); }
sub Azzert_num_lt { return &Azzert_Compare_Impl (sub { return $a <  $b; }, @_); }
sub Azzert_num_le { return &Azzert_Compare_Impl (sub { return $a <= $b; }, @_); }
sub Azzert_num_gt { return &Azzert_Compare_Impl (sub { return $a >  $b; }, @_); }
sub Azzert_num_ge { return &Azzert_Compare_Impl (sub { return $a >= $b; }, @_); }

sub Azzert_str_eq { return &Azzert_Compare_Impl (sub { return $a eq $b; }, @_); }
sub Azzert_str_ne { return &Azzert_Compare_Impl (sub { return $a ne $b; }, @_); }
sub Azzert_str_lt { return &Azzert_Compare_Impl (sub { return $a lt $b; }, @_); }
sub Azzert_str_le { return &Azzert_Compare_Impl (sub { return $a le $b; }. @_); }
sub Azzert_str_gt { return &Azzert_Compare_Impl (sub { return $a gt $b; }, @_); }
sub Azzert_str_ge { return &Azzert_Compare_Impl (sub { return $a ge $b; }, @_); }

sub Azzert_eq     { return &Azzert_str_eq (@_); }
sub Azzert_ne     { return &Azzert_str_ne (@_); }
sub Azzert_lt     { return &Azzert_str_lt (@_); }
sub Azzert_le     { return &Azzert_str_le (@_); }
sub Azzert_gt     { return &Azzert_str_gt (@_); }
sub Azzert_ge     { return &Azzert_str_ge (@_); }

sub Shift
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	
	return shift @$ram;
}

sub ShiftOr
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $mAlternate    =      shift;
	
	return @$ram ? shift @$ram : $mAlternate;
}

sub ShiftOrInvoke
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram           eq 'ARRAY');
	}
	my $rfnAlternate  = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rfnAlternate  eq 'CODE' );
	}
	
	return @$ram ? shift @$ram : $rfnAlternate->($ram, @_);
}

sub ShiftOrAzzert
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram           eq 'ARRAY');
	}
	my $sMsgAlternate =      shift;
	{
		&Azzert (! defined ($sMsgAlternate) || ref $sMsgAlternate eq '');
	}
	
	return @$ram ? shift @$ram : &Azzert (0, defined ($sMsgAlternate) ? $sMsgAlternate : 'ShiftOrAzzert: Empty list !');
}

sub Pop
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram           eq 'ARRAY');
	}
	
	return pop @$ram;
}

sub PopOr
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram           eq 'ARRAY');
	}
	my $mAlternate    =      shift;
	
	return @$ram ? pop @$ram : $mAlternate;
}

sub PopOrInvoke
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram           eq 'ARRAY');
	}
	my $rfnAlternate  = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rfnAlternate  eq 'CODE');
	}
	
	return @$ram ? pop @$ram : $rfnAlternate->($ram, @_);
}

sub PopOrAzzert
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $sMsgAlternate =      shift;
	{
		&Azzert (! defined $sMsgAlternate || ref $sMsgAlternate eq '');
	}
	
	return @$ram ? pop @$ram : &Azzert (0, defined ($sMsgAlternate) ? $sMsgAlternate : 'PopOrAzzert: Empty list !');
}

sub ShiftN
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $n             = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($n));
		&Azzert_num_ge ($n, 0);
	}
	
	return &ShiftNOr ($ram, $n, []);
}

sub ShiftNOr
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram          eq 'ARRAY');
	}
	my $n             = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($n));
		&Azzert_num_ge ($n, 0);
	}
	my $ramAlternate  = @_ ? shift : []        ;
	{
		&Azzert (ref $ramAlternate eq 'ARRAY');
	}
	
	my $iVerb         = 0;
	
	use List::Util qw (min);
	
	my $ram_n0        = scalar @$ram;
	my $n0            = min ($n, $ram_n0);
	
	# [2024-08-20]
	if ($iVerb)
	{
		printf
		(
			"ShiftNOr (\@\$ram (%s), \$n %u, \@\$ramAlternate (%s))...\n",
			join (' ', @$ram),
			$n,
			join (' ', @$ramAlternate)
		);
	}
	
	my @amRet         = splice (@$ram, 0, $n0);
	{
		# [2024-08-16]
		for (my ($i, $j) = ($n0, min ($n, scalar @$ramAlternate)); $i < $j; ++$i)
		{
			push (@amRet, $ramAlternate->[$i]);
		}
		#push (@amRet, (@$ramAlternate) [($n0 .. $n - 1)]);
	}
	
	if ($iVerb)
	{
		printf
		(
			"=> amRet (%s).\n",
			join (' ', @amRet)
		);
	}
	
	return @amRet;
}

sub ShiftNOrInvoke
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram          eq 'ARRAY');
	}
	my $n             = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($n));
		&Azzert_num_ge ($n, 0);
	}
	my $rfnAlternate  = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rfnAlternate eq 'CODE' );
	}
	
	my $ram_n0        = scalar @$ram;
	my $ramAlternate  = $ram_n0 >= $n ? [] : $rfnAlternate->($ram, $n, @_);
	return &ShiftNOr ($ram, $n, $ramAlternate, @_);
}

sub ShiftNOrAzzert
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $n             = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($n));
		&Azzert_num_ge ($n, 0);
	}
	my $sMsgAlternate =      shift;
	{
		&Azzert (! defined $sMsgAlternate || ref $sMsgAlternate eq '');
	}
	
	if (scalar @$ram >= $n)
	{
		return &ShiftNOr ($ram, $n, []);
	}
	else
	{
		my $sMsg = defined ($sMsgAlternate) ? $sMsgAlternate : sprintf ('ShiftNOrAzzert: available %u, requested %u !', scalar @$ram, $n);
		&Azzert (0, $sMsg);
	}
}

sub IndentPrefix
{
	my $n = @_ ? shift : 1;
	
	# [2022-11-03]
	return "\t" x $n;
	#return "  " x $n;
}

sub Indent
{
	my $sx          = @_ ? shift : &Azzert ();
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
				{ &Azzert (! length ($sBuffered)); }
			
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
	my $sx          = @_ ? shift : &Azzert ();
	my $sTitle      = @_ ? shift : 'Untitled';
	my $n           = @_ ? shift : 1;
	my $bChompLines = @_ ? shift : 1;
	
	return sprintf ("%s\n{\n%s}\n\n", $sTitle, Indent ($sx, $n, $bChompLines));
}

sub ArrayToString
{
	my $ras = @_ ? shift : &Azzert ();
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
	my $rhks = @_ ? shift : &Azzert ();
		{ &Azzert (ref $rhks eq 'HASH'); }
	
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
	my $rh = @_ ? shift : &Azzert ();
		{ &Azzert (ref $rh eq 'HASH'); }
	my $ccKey = @_ ? shift : 0;
		{ &Azzert (ref $ccKey eq ''); }
	
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
	my $rasHaystack = @_ ? shift : &Azzert ();
		{ &Azzert (ref $rasHaystack eq 'ARRAY'); }
	my $sNeedle     = @_ ? shift : &Azzert ();
	
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
	my $s0 = @_ ? shift : &Azzert ();
	
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
				&Azzert (length ($sArg));
				
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
				&Azzert ();
			}
		}
	}
	
	return @asRet;
}

sub ArrayElement
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $ki            = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($ki));
		&Azzert_num_eq ($ki, int $ki);
	}
	
	return $ram->[$ki];
}

sub ArrayElementOr
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $ki            = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($ki));
		&Azzert_num_eq ($ki, int $ki);
		if ($ki < 0) { $ki = scalar @$ram + $ki; }
	}
	my $mAlternate    =      shift;
	
	return
		$ki >= 0 && $ki < scalar @$ram ?
			$ram->[$ki]
			:
			$mAlternate;
}

sub ArrayElementOrInvoke
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $ki            = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($ki));
		&Azzert_num_eq ($ki, int $ki);
		if ($ki < 0) { $ki = scalar @$ram + $ki; }
	}
	my $rfnAlternate  = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rfnAlternate eq 'CODE');
	}
	
	return
		$ki >= 0 && $ki < scalar @$ram ?
			$ram->[$ki]
			:
			$rfnAlternate->($ram, $ki, @_);
}

sub ArrayElementOrAzzert
{
	my $ram           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ram eq 'ARRAY');
	}
	my $ki            = @_ ? shift : &Azzert ();
	{
		&Azzert (&LooksLikeNumber ($ki));
		&Azzert_num_eq ($ki, int $ki);
		if ($ki < 0) { $ki = scalar @$ram + $ki; }
	}
	my $sMsgAlternate =      shift;
	{
		&Azzert (! defined $sMsgAlternate || ref $sMsgAlternate eq '');
	}
	
	return
		$ki >= 0 && $ki < scalar @$ram ?
			$ram->[$ki]
			:
			&Azzert (0, defined ($sMsgAlternate) ? $sMsgAlternate : sprintf ("ArrayElementOrAzzert (size %u, index %d) !", scalar @$ram, $ki));
}

sub ArrayElementMust
{
	# [2024-08-15 :x:x] TODO: `goto` ?!
	return &ArrayElementOrAzzert (@_);
}

sub ArrayElementOrSub
{
	# [2024-08-21 :*]
	return &ArrayElementOrInvoke (@_);
}

sub HashElement
{
	my $rhm           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rhm eq 'HASH');
	}
	my $ks            = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ks eq '');
	}
	
	return $rhm->{$ks};
}

sub HashElementOr
{
	my $rhm           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rhm eq 'HASH');
	}
	my $ks            = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ks eq '');
	}
	my $mAlternate    =      shift;
	
	return
		exists $rhm->{$ks} ?
			$rhm->{$ks}
			:
			$mAlternate;
}

sub HashElementOrInvoke
{
	my $rhm           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rhm eq 'HASH');
	}
	my $ks            = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ks eq '');
	}
	my $rfnAlternate  = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rfnAlternate eq 'CODE');
	}
	
	return
		exists $rhm->{$ks} ?
			$rhm->{$ks}
			:
			$rfnAlternate->($rhm, $ks, @_);
}

sub HashElementOrAzzert
{
	my $rhm           = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $rhm eq 'HASH');
	}
	my $ks            = @_ ? shift : &Azzert ();
	{
		&Azzert (ref $ks eq '');
	}
	my $sMsgAlternate =      shift;
	{
		&Azzert (! defined $sMsgAlternate || ref $sMsgAlternate eq '');
	}
	
	return
		exists $rhm->{$ks} ?
			$rhm->{$ks}
			:
			&Azzert (0, defined $sMsgAlternate ? $sMsgAlternate : sprintf ('HashElementOrAzzert (..., %s) !', "'${ks}'"));
}

sub HashElementMust
{
	# [2024-08-15 :x:x] TODO: `goto` ?!
	return &HashElementOrAzzert (@_);
}

sub HashElementOrSub
{
	# [2024-08-21 :*]
	return &HashElementOrInvoke (@_);
}

sub StringToNumber
{
	my $s0    = @_ ? shift : &Azzert ();
	my $iBase = @_ ? shift : 10;
	my $iSign = 1;
	{
		for (;;)
		{
			my $bResult = $s0 =~ m/^\s*([+-]?)\s*(.*?)\s*$/;
			&Azzert ($bResult);
			
			$s0 = $2;
			
			if ($1 eq '')
				{ last; }
			elsif ($1 eq '-')
				{ $iSign = - $iSign; }
			else
				{ &Azzert_eq ($1, '+'); }
		}
	}
	
	#printf ("iSign %+d.\n", $iSign);
	
	my $s1 = '';
	{
		if    ($s0 =~ m/^ 0[Xx]   ([_'0-9A-Fa-f]+)        $/x) { $iBase = 16; $s1 = $1; }
		elsif ($s0 =~ m/^         ([_'0-9A-Fa-f]+) [Hh]   $/x) { $iBase = 16; $s1 = $1; }
		elsif ($s0 =~ m/^ 0[Bb]   ([_'0-1]      +)        $/x) { $iBase =  2; $s1 = $1; }
		elsif ($s0 =~ m/^         ([_'0-1]      +) [Bb]   $/x) { $iBase =  2; $s1 = $1; }
		elsif ($s0 =~ m/^ 0[OoQq] ([_'0-7]      +)        $/x) { $iBase =  8; $s1 = $1; }
		elsif ($s0 =~ m/^         ([_'0-7]      +) [OoQq] $/x) { $iBase =  8; $s1 = $1; }
		elsif ($s0 =~ m/^         ([_'0-9]      +)        $/x) { $iBase = 10; $s1 = $1; }
		else                                                   { return undef; }
	}
	
	my ($rv, $nDigits) = (0, 0);
	{
		my $sUpper = '0123456789ABCDEF';
		
		#printf ("s1 %s.\n", "'${s1}'");
		
		my $cc = length ($s1);
		for (my $ic = 0; $ic < $cc; ++$ic)
		{
			my $c     = substr ($s1, $ic, 1);
			my $digit = index ($sUpper, uc ($c));
			
			#printf ("digit %+3d.\n", $digit);
			
			if ($digit >= $iBase)
				{ return undef; }
			elsif ($digit >= 0)
				# [2024-07-29] TODO: Check overflow/exactness ?
				{ $rv *= $iBase; $rv += $digit; ++$nDigits; }
		}
	}
	
	return $nDigits ? $iSign * $rv : undef;
}

sub IsHashOrObject
{
	my $self = @_ ? shift : &Azzert ();
	
	# [2024-08-13 :|] Desperate attempts to avoid 'useless use' warnings from Perl.
	eval { sub f { my $self = shift; return scalar keys %$self; } f ($self); };
	return $@ eq '';
}

sub GetOrSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_) { my $value = shift; $self->{$sProperty} = $value; return $self; }
	else    { return $self->{$sProperty}; }
}

our $value;

sub GetOrCheckSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $rfnCheck  = @_ ? shift : &Azzert (); if (defined $rfnCheck) { &Azzert (ref $rfnCheck eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $xValue = shift;
		
		# [2025-05-04]
		#   We make the argument available via the `$value` named variable.
		#   Currently, we also keep the old way of passing the argument as the first positional argument
		#   (in order to support existing code).
		#   Initially, we thought that, in the future, we might switch to only supporting the `$value` named variable.
		#   However, after having gained some understanding of the limitations of `local`,
		#   we now think that we might always keep the old approach and actually deprecate-or-remove the new approach.
		#
		#my $bResult = defined $rfnCheck ? $rfnCheck->($value, @_) : 1;
		## [2024-07-26] TODO:
		##   Should we warn or silently reject or loudly reject ?!
		##   Currently, we let the Client decide, e.g. by writing `if (! ...) { return 0; } return 1;` or `&Azzert (...); return 1;`.
		##&Azzert ($bResult);
		##
		#
		my $bResult = 1;
		{
			if (defined ($rfnCheck))
			{
				local $value = $xValue;
				$bResult = $rfnCheck->($xValue, @_);
			}
		}
		
		if ($bResult) { $self->{$sProperty} = $xValue; }
		return $self;
	}
	else
	{
		return $self->{$sProperty};
	}
}

our $rvalue;

sub GetOrAlterSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $rfnAlter  = @_ ? shift : &Azzert (); if (defined $rfnAlter) { &Azzert (ref $rfnAlter eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $xValue = shift;
		my $bResult = 1;
		{
			# [2025-05-04] Please kindly see today's notes for `GetOrCheckSetObjectProperty`.
			if (defined ($rfnAlter))
			{
				local $rvalue = \$xValue;
				$bResult = $rfnAlter->(\$xValue, @_);
			}
		}
		if ($bResult) { $self->{$sProperty} = $xValue; }
		return $self;
	}
	else
	{
		return $self->{$sProperty};
	}
}

sub GetOrDefAlterSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $xDefValue = @_ ? shift : &Azzert ();
	my $rfnAlter  = @_ ? shift : &Azzert (); if (defined $rfnAlter) { &Azzert (ref $rfnAlter eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $xValue = shift; if (! defined $xValue) { $xValue = $xDefValue; }
		my $bResult = 1;
		{
			if (defined ($rfnAlter))
			{
				local $rvalue = \$xValue;
				$bResult = $rfnAlter->(\$xValue, @_);
			}
		}
		if ($bResult) { $self->{$sProperty} = $xValue; }
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
	my $x             = @_ ? shift : &Azzert ();
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
	my $sArg = @_ ? shift : &Azzert ();
	
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
	my $rasArgs = @_ ? shift : &Azzert (); { Azzert (ref $rasArgs eq 'ARRAY'); }
	return join (' ', map { &QuoteArg ($_); } @$rasArgs);
}

1;

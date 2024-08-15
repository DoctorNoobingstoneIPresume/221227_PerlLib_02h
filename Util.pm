# [2022-11-03] Stolen from "F:/Adder1F/Projects/2022/221027_Output_of_readelf_01h/221027_ElfAnalyzer_PerlEdition/Util.pm":

package Util;

use Exporter qw (import);
our @EXPORT = qw
(
	LooksLikeNumber
	printf_2 SeverityText printf_2s
	EMERG PANIC ALERT CRIT ERR ERROR WARNING WARN NOTICE INFO DEBUG SEVERITY_LEVEL
	Azzert
	AzzertSub
	Azzert_Compare_Impl
	Azzert_num_eq Azzert_num_ne Azzert_num_lt Azzert_num_le Azzert_num_gt Azzert_num_ge
	Azzert_str_eq Azzert_str_ne Azzert_str_lt Azzert_str_le Azzert_str_gt Azzert_str_ge
	Azzert_eq     Azzert_ne     Azzert_lt     Azzert_le     Azzert_gt     Azzert_ge
	ShiftOrAzzert ShiftOr PopOrAzzert PopOr
	IndentPrefix Indent IndentWithTitle ArrayToString HashMapKeysToString HashToString IndexOfStringInArray
	SplitCommandLine
	ArrayElementMust ArrayElementOr ArrayElementOrSub ArrayElementOrAzzert
	HashElementMust  HashElementOr  HashElementOrSub  HashElementOrAzzert
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
	my $sMessage   = shift;
		{ if (! defined ($sMessage)) { $sMessage = 'No message.'; } }
	
	if (! $bCondition)
	{
		{ use IO::Handle; STDOUT->flush (); }
		{ use Carp; croak ("Error: Azzertion has failed. ${sMessage}"); }
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
	
	my $bResult = $rFunction->($x, $y);
	if (! $bResult)
	{
		my $sMessage = sprintf
		(
			'%s has failed (%s vs %s) !%s',
			"'${sFunctionName}'", "'${x}'", "'${y}'", defined ($sMessage) ? " ${sMessage}" : ''
		);
		
		Azzert (0, $sMessage);
	}
}

# [2024-07-29] `Azzert_(num|str|)_(eq|ne|lt|le|gt|ge)`:
#   TODO: Could we "generate" the Perl code with less repetition ? :)

sub Azzert_num_eq { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x == $y; }, @_); }
sub Azzert_num_ne { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x != $y; }, @_); }
sub Azzert_num_lt { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x <  $y; }, @_); }
sub Azzert_num_le { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x <= $y; }, @_); }
sub Azzert_num_gt { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x >  $y; }, @_); }
sub Azzert_num_ge { return &Azzert_Compare_Impl (sub { my ($x, $y) = @_; return $x >= $y; }, @_); }

sub Azzert_str_eq { return &Azzert_Compare_Impl (sub { return $_ [0] eq $_ [1]; }, @_); }
sub Azzert_str_ne { return &Azzert_Compare_Impl (sub { return $_ [0] ne $_ [1]; }, @_); }
sub Azzert_str_lt { return &Azzert_Compare_Impl (sub { return $_ [0] lt $_ [1]; }, @_); }
sub Azzert_str_le { return &Azzert_Compare_Impl (sub { return $_ [0] le $_ [1]; }. @_); }
sub Azzert_str_gt { return &Azzert_Compare_Impl (sub { return $_ [0] gt $_ [1]; }, @_); }
sub Azzert_str_ge { return &Azzert_Compare_Impl (sub { return $_ [0] ge $_ [1]; }, @_); }

sub Azzert_eq     { return &Azzert_str_eq (@_); }
sub Azzert_ne     { return &Azzert_str_ne (@_); }
sub Azzert_lt     { return &Azzert_str_lt (@_); }
sub Azzert_le     { return &Azzert_str_le (@_); }
sub Azzert_gt     { return &Azzert_str_gt (@_); }
sub Azzert_ge     { return &Azzert_str_ge (@_); }

sub ShiftOrAzzert
{
	my $rax = @_ ? shift : &Azzert ();
	return @$rax ? shift @$rax : &Azzert (0, 'ShiftOrAzzert: Empty list !');
}

sub ShiftOr
{
	my $rax = @_ ? shift : &Azzert ();
	return @$rax ? shift @$rax : shift;
}

sub PopOrAzzert
{
	my $rax = @_ ? shift : &Azzert ();
	return @$rax ? pop @$rax : &Azzert (0, 'PopOrAzzert: Empty list !');
}

sub PopOr
{
	my $rax = @_ ? shift : &Azzert ();
	return @$rax ? pop @$rax : shift;
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

sub ArrayElementMust
{
	# [2024-08-15 :x:x] TODO: `goto` ?!
	return &ArrayElementOrAzzert (@_);
}

sub ArrayElementOr
{
	my $ra           = @_ ? shift : &Azzert (); &Azzert (ref $ra  eq 'ARRAY');
	my $ki           = @_ ? shift : &Azzert (); &Azzert (&LooksLikeNumber ($ki));
	my $mAlternative =      shift;
	
	return $ki >= 0 && $ki < scalar (@$ra) ? $ra->[$ki] : $mAlternative;
}

sub ArrayElementOrSub
{
	my $ra           = @_ ? shift : &Azzert (); &Azzert (ref $ra  eq 'ARRAY');
	my $ki           = @_ ? shift : &Azzert (); &Azzert (&LooksLikeNumber ($ki));
	my $rfn          = @_ ? shift : &Azzert (); &Azzert (ref $rfn eq 'CODE');
	
	return $ki >= 0 && $ki < scalar (@$ra) ? $ra->[$ki] : $rfn->($ra, $ki, @_);
}

sub ArrayElementOrAzzert
{
	my $ra           = @_ ? shift : &Azzert (); &Azzert (ref $ra  eq 'ARRAY');
	my $ki           = @_ ? shift : &Azzert (); &Azzert (&LooksLikeNumber ($ki));
	
	return $ki >= 0 && $ki < scalar (@$ra) ? $ra->[$ki] : &Azzert (0, @_);
}

sub HashElementMust
{
	# [2024-08-15 :x:x] TODO: `goto` ?!
	return &HashElementOrAzzert (@_);
}

sub HashElementOr
{
	my $rh           = @_ ? shift : &Azzert (); &Azzert (ref $rh  eq 'HASH');
	my $ks           = @_ ? shift : &Azzert (); &Azzert (ref $ks  eq '');
	my $mAlternative = @_ ? shift : undef;
	
	return exists $rh->{$ks} ? $rh->{$ks} : $mAlternative;
}

sub HashElementOrSub
{
	my $rh           = @_ ? shift : &Azzert (); &Azzert (ref $rh  eq 'HASH');
	my $ks           = @_ ? shift : &Azzert (); &Azzert (ref $ks  eq '');
	my $rfn          = @_ ? shift : &Azzert (); &Azzert (ref $rfn eq 'CODE');
	
	return exists $rh->{$ks} ? $rh->{$ks} : $rfn->($rh, $ks, @_);
}

sub HashElementOrAzzert
{
	my $rh           = @_ ? shift : &Azzert (); &Azzert (ref $rh  eq 'HASH');
	my $ks           = @_ ? shift : &Azzert (); &Azzert (ref $ks  eq '');
	
	return exists $rh->{$ks} ? $rh->{$ks} : &Azzert (0, @_);
}

sub StringToNumber
{
	my $s0    = @_ ? shift : Azzert ();
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
	my $sProperty = @_ ? shift : Azzert (); &Azzert (ref $sProperty eq '');
	my $self      = @_ ? shift : Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_) { my $value = shift; $self->{$sProperty} = $value; return $self; }
	else    { return $self->{$sProperty}; }
}

sub GetOrCheckSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $rfnCheck  = @_ ? shift : &Azzert (); if (defined $rfnCheck) { &Azzert (ref $rfnCheck eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $value = shift;
		
		my $bResult = defined $rfnCheck ? $rfnCheck->($value, @_) : 1;
		# [2024-07-26] TODO:
		#   Should we warn or silently reject or loudly reject ?!
		#   Currently, we let the Client decide, e.g. by writing `if (! ...) { return 0; } return 1;` or `&Azzert (...); return 1;`.
		#&Azzert ($bResult);
		#
		if ($bResult) { $self->{$sProperty} = $value; }
		return $self;
	}
	else
	{
		return $self->{$sProperty};
	}
}

sub GetOrAlterSetObjectProperty
{
	my $sProperty = @_ ? shift : &Azzert (); &Azzert (ref $sProperty eq '');
	my $rfnAlter  = @_ ? shift : &Azzert (); if (defined $rfnAlter) { &Azzert (ref $rfnAlter eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $value = shift;
		my $bResult = defined $rfnAlter ? $rfnAlter->(\$value, @_) : 1;
		if ($bResult) { $self->{$sProperty} = $value; }
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
	my $xDefValue = @_ ? shift : &Azzert (); &Azzert (ref $xDefValue eq '');
	my $rfnAlter  = @_ ? shift : &Azzert (); if (defined $rfnAlter) { &Azzert (ref $rfnAlter eq 'CODE'); }
	my $self      = @_ ? shift : &Azzert (); &Azzert (&IsHashOrObject ($self));
	
	if (@_)
	{
		my $value = shift; if (! defined $value) { $value = $xDefValue; }
		my $bResult = defined $rfnAlter ? $rfnAlter->(\$value, @_) : 1;
		if ($bResult) { $self->{$sProperty} = $value; }
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
	return join (' ', map { &QuoteArg ($_); } @$rasArgs);
}

1;

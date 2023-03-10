# [2022-11-03] Stolen from "F:/Adder1F/Projects/2022/221027_Output_of_readelf_01h/221027_ElfAnalyzer_PerlEdition/Util.pm":

package Util;
use Exporter qw (import);
our @EXPORT = qw (Azzert IndentPrefix Indent IndentWithTitle ArrayToString HashMapKeysToString IndexOfStringInArray);

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

sub IndentPrefix
{
	my $n = @_ ? shift : 1;
	
	# [2022-11-03]
	return "\t" x $n;
	#return "  " x $n;
}

sub Indent
{
	my $sx = @_ ? shift : Azzert ();
	my $n  = @_ ? shift : 1;
	
	my $sy = '';
	{
		my $sLinePrefix = IndentPrefix ($n);
		
		my $sBuffered = '';
		my $bAnything = 0;
		
		my $nc = length ($sx);
		for (my $ic = 0; $ic <= $nc; ++$ic)
		{
			if ($bAnything)
				{ Azzert (! length ($sBuffered)); }
			
			my $c   = $ic < $nc ? substr ($sx, $ic, 1) : '';
			my $cod = $ic < $nc ? ord ($c)             : 0 ;
			
			if ($cod == 0xA || ! $cod)
			{
				if ($cod)
					{ $sy .= $c; }
				
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
					$sy .= $sLinePrefix . $sBuffered . $c;
					$sBuffered = '';
					$bAnything = 1;
				}
			}
		}
	}
	
	return $sy;
}

sub IndentWithTitle
{
	my $sx     = @_ ? shift : Azzert ();
	my $sTitle = @_ ? shift : 'Untitled';
	my $n      = @_ ? shift : 1;
	
	return sprintf ("%s\n{\n%s}\n\n", $sTitle, Indent ($sx, $n));
}

sub ArrayToString
{
	my $ras = @_ ? shift : Azzert ();
	
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

1;

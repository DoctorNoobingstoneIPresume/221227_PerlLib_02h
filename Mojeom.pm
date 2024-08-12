package Mojeom;
use Util;
use strict; use warnings;

sub CreateObject
{
	my $sClassName = @_ ? shift : &Azzert ();
	
	my $self =
	{
		'r' => 1,
		'g' => 1,
		'b' => 0,
		'a' => 1
	};
	
	return bless ($self, $sClassName);
}

sub Nuance
{
	my $ks = @_ ? shift : &Azzert ();
	
	return &GetOrCheckSetObjectProperty
	(
		$ks,
		sub { my $value = shift; return $value >= 0 && $value <= 1; },
		@_
	);
}

sub R { return &Nuance ('r', @_); }
sub G { return &Nuance ('g', @_); }
sub B { return &Nuance ('b', @_); }
sub A { return &GetOrCheckSetObjectProperty ('a', undef, @_); }

sub ToString
{
	my $self = @_ ? shift : &Azzert ();
	return sprintf ('R %g, G %g, B %g, A %g', $self->R (), $self->G (), $self->B (), $self->A ());
}

1;

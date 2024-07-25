package DestroyGuard;
use Util;
use strict; use warnings;

sub CreateObject
{
	my $sClassName = @_ ? shift : &Azzert ();
	
	my $self =
	{
		'rfnOnDestroy' => shift
	};
	
	return bless ($self, $sClassName);
}

sub OnDestroy { return &GetOrSetObjectProperty ('rfnOnDestroy', @_); }

sub DESTROY
{
	#use Util;
	my $self = @_ ? shift : &Azzert ();
	
	my $ks = 'rfnOnDestroy';
	if (defined ($self->{$ks}))
	{
		&Azzert (ref ($self->{$ks}) eq 'CODE');
		$self->{$ks}->();
	}
}

1;

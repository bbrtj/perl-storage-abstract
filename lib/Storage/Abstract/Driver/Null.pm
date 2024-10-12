package Storage::Abstract::Driver::Null;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

extends 'Storage::Abstract::Driver';

sub store_impl
{
	# don't store anywhere
}

sub is_stored_impl
{
	# never true
	return !!0;
}

sub retrieve_impl
{
	# will never be called
}

sub dispose_impl
{
	# will never be called
}

1;

__END__


package Storage::Abstract::Driver;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Types::Common -types;

use Storage::Abstract::X;

sub handle_from_string_ref
{
	my ($self, $string_ref) = @_;

	open my $fh, '<', $string_ref
		or Storage::Abstract::X::HandleError->raise($!);

	return $fh;
}

sub slurp_handle
{
	my ($self, $handle) = @_;

	my $slurped = do {
		local $/;
		readline $handle;
	};

	Storage::Abstract::X::HandleError->raise($!)
		unless defined $slurped;

	return $slurped;
}

sub common_properties
{
	my ($self) = @_;

	return {
		mtime => time,
	};
}

sub store
{
	my ($self, $name, $handle) = @_;

	...;
}

sub retrieve
{
	my ($self, $name, $properties) = @_;

	...;
}

1;

__END__


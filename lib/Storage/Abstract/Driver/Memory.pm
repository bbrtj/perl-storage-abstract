package Storage::Abstract::Driver::Memory;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

extends 'Storage::Abstract::Driver';

has field 'files' => (
	isa => HashRef,
	default => sub { {} },
);

sub store_impl
{
	my ($self, $name, $handle) = @_;
	my $files = $self->files;

	$files->{$name}{content} = $self->slurp_handle($handle);
	$files->{$name}{properties} = $self->common_properties;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	return exists $self->files->{$name};
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;
	my $files = $self->files;

	if ($properties) {
		%{$properties} = %{$files->{$name}{properties}};
	}

	return $self->handle_from_string_ref(\$files->{$name}{content});
}

1;

__END__


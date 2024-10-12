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

	$files->{$name}{properties} = $self->common_properties;

	open my $fh, '>', \$files->{$name}{content}
		or Storage::Abstract::X::StorageError->raise("Could not open storage: $!");

	$self->copy_handle($handle, $fh);

	close $fh
		or Storage::Abstract::X::StorageError->raise("Could not close handle: $!");
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

	return $self->open_handle(\$files->{$name}{content});
}

sub dispose_impl
{
	my ($self, $name) = @_;

	delete $self->files->{$name};
}

1;

__END__


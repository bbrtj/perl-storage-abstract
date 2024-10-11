package Storage::Abstract::Driver::Memory;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Types::Common -types;

extends 'Storage::Abstract::Driver';

has field 'files' => (
	isa => HashRef,
	default => sub { {} },
);

sub store
{
	my ($self, $name, $handle) = @_;
	my $files = $self->files;

	$files->{$name}{content} = $self->slurp_handle($handle);
	$files->{$name}{properties} = $self->common_properties;
	return;
}

sub retrieve
{
	my ($self, $name, $properties) = @_;
	my $files = $self->files;

	Storage::Abstract::X::NotFound->raise("file $name was not found")
		unless exists $files->{$name};

	if ($properties) {
		%{$properties} = %{$files->{$name}{properties}};
	}

	return $self->handle_from_string_ref(\$files->{$name}{content});
}

1;

__END__


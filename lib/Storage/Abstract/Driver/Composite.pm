package Storage::Abstract::Driver::Composite;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use Feature::Compat::Try;
use Scalar::Util qw(blessed);

extends 'Storage::Abstract::Driver';

has param 'sources' => (
	coerce => ArrayRef [
		(InstanceOf ['Storage::Abstract'])
		->plus_coercions(HashRef, q{ Storage::Abstract->new(%$_) })
	],
);

has field 'errors' => (
	isa => ArrayRef,
	writer => -hidden,
);

has field '_cache' => (
	isa => HashRef,
	clearer => -public,
	lazy => sub { {} },
);

sub _run_on_source
{
	my ($self, $callback, $source, $errors) = @_;
	try {
		return $callback->($source);
	}
	catch ($e) {
		push @$errors, [$source, $e];
		return !!0;
	}
}

sub _run_on_sources
{
	my ($self, $name, $callback) = @_;
	my $finished = !!0;
	my @errors;

	# run on one cached source
	my $cached_source = $self->_cache->{$name};
	if ($cached_source) {
		$finished = $self->_run_on_source($callback, $cached_source, \@errors);
	}

	# if there was no cached source or $callback did not return true, do it on
	# all sources
	if (!$finished) {
		@errors = ();
		foreach my $source (@{$self->sources}) {
			if ($finished = $self->_run_on_source($callback, $source, \@errors)) {
				$self->_cache->{$name} = $source;
				last;
			}
		}
	}

	if (@errors) {
		$self->_set_errors(\@errors);
	}

	return $finished;
}

sub store_impl
{
	my ($self, $name, $handle) = @_;

	my $stored = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;
			return !!0 if $source->readonly;

			$source->store($name, $handle);
			return !!1;
		}
	);

	Storage::Abstract::X::StorageError->raise("None of the sources were able to store $name")
		unless $stored;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	my $stored = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			return $source->is_stored($name);
		}
	);

	return $stored;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	my $retrieved = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				return $source->retrieve($name, $properties);
			}

			return !!0;
		}
	);

	Storage::Abstract::X::StorageError->raise("Could not retrieve $name")
		unless $retrieved;

	return $retrieved;
}

sub dispose_impl
{
	my ($self, $name) = @_;

	my $disposed = $self->_run_on_sources(
		$name,
		sub {
			my $source = shift;
			return !!0 if $source->readonly;

			if ($source->is_stored($name)) {
				$source->dispose($name);
				return !!1;
			}

			return !!0;
		}
	);

	Storage::Abstract::X::StorageError->raise("Could not dispose $name")
		unless $disposed;
}

1;

__END__


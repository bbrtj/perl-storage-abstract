package Storage::Abstract::Driver::Composite;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Types::Common -types;

use Feature::Compat::Try;
use Scalar::Util qw(blessed);

extends 'Storage::Abstract::Driver';

has param 'sources' => (
	coerce => (ArrayRef [InstanceOf ['Storage::Abstract']])
		->plus_coercions(
			ArrayRef [HashRef], q{
			[map { Storage::Abstract->new(%$_) } @$_]
		}
		),
);

has field 'errors' => (
	writer => -hidden,
);

sub _run_on_sources
{
	my ($self, $callback, $on_error) = @_;

	my @errors;
	foreach my $source (@{$self->sources}) {
		try {
			last unless $callback->($source);
		}
		catch ($e) {
			if (!$on_error || !$on_error->($e)) {
				push @errors, [$source, $e];
			}
		}
	}

	if (@errors) {
		$self->_set_errors(\@errors);
	}
}

sub store_impl
{
	my ($self, $name, $handle) = @_;

	my $stored = !!0;
	$self->_run_on_sources(
		sub {
			my $source = shift;

			if (!$source->readonly) {
				$source->store($name, $handle);
				$stored = !!1;
				return !!0;
			}

			return !!1;
		}
	);

	Storage::Abstract::X::StorageError->raise("None of the sources were able to store")
		unless $stored;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	my $stored = !!0;
	$self->_run_on_sources(
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				$stored = !!1;
				return !!0;
			}

			return !!1;
		}
	);

	return $stored;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	my $retrieved;
	$self->_run_on_sources(
		sub {
			my $source = shift;

			my $retrieved = $source->retrieve($name, $properties);
			return !!0;
		},
		sub {
			my $e = shift;
			return !(blessed $e && $e->isa('Storage::Abstract::X::NotFound'));
		}
	);

	# it must be stored somewhere, since we passed is_stored check - therefore
	# no need to check for error
	return $retrieved;
}

1;

# TODO: cache in which source a file is stored and update there if it isn't readonly

__END__


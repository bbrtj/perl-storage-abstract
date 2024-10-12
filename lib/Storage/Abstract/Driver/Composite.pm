package Storage::Abstract::Driver::Composite;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
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
	isa => ArrayRef,
	writer => -hidden,
);

has field '_cache' => (
	isa => HashRef,
	default => sub { {} },
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
			if ($self->_run_on_source($callback, $source, \@errors)) {
				$self->_cache->{$name} = $source;
				last;
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
		$name,
		sub {
			my $source = shift;
			return !!0 if $source->readonly;

			$source->store($name, $handle);
			$stored = !!1;
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
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				$stored = !!1;
				return !!1;
			}

			return !!0;
		}
	);

	return $stored;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	my $retrieved;
	$self->_run_on_sources(
		$name,
		sub {
			my $source = shift;

			if ($source->is_stored($name)) {
				$retrieved = $source->retrieve($name, $properties);
				return !!1;
			}

			return !!0;
		}
	);

	# it must be stored somewhere, since we passed is_stored check - therefore
	# no need to check for error (unless race?)
	return $retrieved;
}

1;

__END__


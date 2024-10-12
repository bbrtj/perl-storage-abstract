package Storage::Abstract::Driver;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

use Scalar::Util qw(blessed);
use Storage::Abstract::X;

# Not using File::Spec here, because paths must be unix-like regardless of
# local OS
use constant UPDIR_STR => '..';
use constant CURDIR_STR => '.';
use constant DIRSEP_STR => '/';

has param 'readonly' => (
	writer => 1,
	isa => Bool,
	default => !!0,
);

# HELPERS

# this is intentionally not portable - only drivers working on an actual
# filesystem should port this unix-like path to its own representation
sub resolve_path
{
	my ($self, $name) = @_;

	my @path = split DIRSEP_STR, $name, -1;
	Storage::Abstract::X::PathError->raise("path $name is empty")
		if !@path;

	my $i = 0;
	my $last_ok = 1;
	while ($i < @path) {
		if ($path[$i] eq UPDIR_STR) {
			Storage::Abstract::X::PathError->raise("path $name is trying to leave root")
				if $i == 0;

			splice @path, $i - 1, 2;
			$last_ok = 0;
			$i -= 1;
		}
		elsif ($path[$i] eq '' || $path[$i] eq CURDIR_STR) {
			splice @path, $i, 1;
			$last_ok = 0;
		}
		else {
			$i += 1;
			$last_ok = 1;
		}
	}

	Storage::Abstract::X::PathError->raise("path $name has no filename")
		unless $last_ok;

	return join DIRSEP_STR, @path;
}

sub open_handle
{
	my ($self, $arg) = @_;
	return $arg
		if blessed $arg && $arg->isa('IO::Handle');

	open my $fh, '<:raw', $arg
		or Storage::Abstract::X::HandleError->raise((ref $arg ? '' : "$arg: ") . $!);

	return $fh;
}

sub copy_handle
{
	my ($self, $handle_from, $handle_to) = @_;

	# no extra behavior of print
	local $\;

	my $read = sub { read $_[0], $_[1], 8 * 1024 };
	my $write = sub { print {$_[0]} $_[1] };

	# can use sysread / syswrite?
	if (fileno $handle_from != -1 && fileno $handle_to != -1) {
		$read = sub { sysread $_[0], $_[1], 128 * 1024 };
		$write = sub {
			my $written = 0;
			while ($written < $_[2]) {
				my $res = syswrite $_[0], $_[1], $_[2], $written;
				return undef unless defined $res;
				$written += $res;
			}

			return 1;
		};
	}

	my $buffer;
	while ('copying') {
		my $bytes = $read->($handle_from, $buffer);

		Storage::Abstract::X::HandleError->raise("error reading from handle: $!")
			unless defined $bytes;
		last if $bytes == 0;
		$write->($handle_to, $buffer, $bytes)
			or Storage::Abstract::X::StorageError->raise("error during file copying: $!");
	}
}

sub common_properties
{
	my ($self) = @_;

	return {
		mtime => time,
	};
}

# TO BE IMPLEMENTED IN SUBCLASSES

sub store_impl
{
	my ($self, $name, $handle) = @_;

	...;
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	...;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	...;
}

sub dispose_impl
{
	my ($self, $name, $handle) = @_;

	...;
}

# PUBLIC INTERFACE

sub store
{
	my ($self, $name, $handle) = @_;

	if (ref $handle ne 'GLOB') {
		Storage::Abstract::X::HandleError->raise('handle argument is not defined')
			unless defined $handle;

		$handle = $self->open_handle($handle);
	}

	Storage::Abstract::X::StorageError->raise('storage is readonly')
		if $self->readonly;

	$self->store_impl($self->resolve_path($name), $handle);
	return;
}

sub is_stored
{
	my ($self, $name) = @_;

	return $self->is_stored_impl($self->resolve_path($name));
}

sub retrieve
{
	my ($self, $name, $properties) = @_;
	my $path = $self->resolve_path($name);

	Storage::Abstract::X::NotFound->raise("file $name was not found")
		unless $self->is_stored_impl($path);

	return $self->retrieve_impl($path, $properties);
}

sub dispose
{
	my ($self, $name) = @_;

	Storage::Abstract::X::StorageError->raise('storage is readonly')
		if $self->readonly;

	my $path = $self->resolve_path($name);

	Storage::Abstract::X::NotFound->raise("file $name was not found")
		unless $self->is_stored_impl($path);

	$self->dispose_impl($path);
	return;
}

1;

__END__


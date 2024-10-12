package Storage::Abstract::Driver;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

use Storage::Abstract::X;

# Not using File::Spec here, because paths must be unix-like regardless of
# local OS
use constant UPDIR_STR => '..';
use constant CURDIR_STR => '.';
use constant DIRSEP_STR => '/';

# Copy 8 kB at once
use constant COPY_SIZE => 8 * 1024;

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

	open my $fh, '<', $arg
		or Storage::Abstract::X::HandleError->raise((ref $arg ? '' : "$arg: ") . $!);

	return $fh;
}

sub copy_handle
{
	my ($self, $handle, $callback) = @_;
	my $pos = tell $handle;
	my $buffer;

	while ('copying') {
		my $bytes = read $handle, $buffer, COPY_SIZE;

		Storage::Abstract::X::HandleError->raise("error reading from handle: $!")
			unless defined $bytes;
		last if $bytes == 0;
		$callback->($buffer);
	}

	seek $handle, $pos, 0;
}

sub slurp_handle
{
	my ($self, $handle) = @_;

	my $pos = tell $handle;
	my $slurped = do {
		local $/;
		readline $handle;
	};
	seek $handle, $pos, 0;

	Storage::Abstract::X::HandleError->raise($! || 'no error - handle EOF?')
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

	if (!defined fileno $handle) {
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


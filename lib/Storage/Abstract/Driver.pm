package Storage::Abstract::Driver;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Types::Common -types;

use Storage::Abstract::X;

# not using File::Spec here, because paths must be unix-like regardless of
# local OS
use constant UPDIR_STR => '..';
use constant CURDIR_STR => '.';
use constant DIRSEP_STR => '/';

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

# PUBLIC INTERFACE

sub store
{
	my ($self, $name, $handle) = @_;

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

1;

__END__


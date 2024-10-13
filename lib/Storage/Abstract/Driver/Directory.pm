package Storage::Abstract::Driver::Directory;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use namespace::autoclean;

use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);

# need this in BEGIN block because we use constants from this package
BEGIN { extends 'Storage::Abstract::Driver' }

# This driver deals with OS filesystem directly, so these must be
# system-specific. Unix paths from Storage::Abstract::Driver must be converted
# to paths on this OS
use constant UPDIR_STR => File::Spec->updir;
use constant CURDIR_STR => File::Spec->curdir;
use constant DIRSEP_STR => File::Spec->catfile('', '');

has param 'directory' => (
	isa => SimpleStr->where(q{-d}),
);

sub resolve_path
{
	my ($self, $name) = @_;

	my $resolved = $self->SUPER::resolve_path($name);
	if (Storage::Abstract::Driver::DIRSEP_STR ne DIRSEP_STR) {
		Storage::Abstract::X::PathError->raise("System-specific dirsep in file path $name")
			if $resolved =~ quotemeta DIRSEP_STR;
	}

	my @parts = split Storage::Abstract::Driver::DIRSEP_STR, $resolved;

	if (Storage::Abstract::Driver::UPDIR_STR ne UPDIR_STR || Storage::Abstract::Driver::CURDIR_STR ne CURDIR_STR) {
		Storage::Abstract::X::PathError->raise("System-specific updir or curdir in file path $name")
			unless @parts == File::Spec->no_upwards(@parts);
	}

	return File::Spec->catfile($self->directory, @parts);
}

sub store_impl
{
	my ($self, $name, $handle) = @_;

	my $directory = dirname($name);
	make_path($directory) unless -e $directory;

	open my $fh, '>:raw', $name
		or Storage::Abstract::X::StorageError->raise("$name: $!");

	$self->copy_handle($handle, $fh);

	close $fh
		or Storage::Abstract::X::StorageError->raise("$name: $!");
}

sub is_stored_impl
{
	my ($self, $name) = @_;

	return -f $name;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;

	if ($properties) {
		my @stat = stat $name;
		%{$properties} = (
			size => $stat[7],
			mtime => $stat[9],
		);
	}

	return $self->open_handle($name);
}

sub dispose_impl
{
	my ($self, $name) = @_;

	unlink $name
		or Storage::Abstract::X::StorageError->raise("$name: $!");
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Directory - Local directory storage

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'directory',
		directory => '/path/to/dir',
	);

=head1 DESCRIPTION

This driver will store files in a local directory.

Driver will perform mapping of paths from Unix to local OS. If the paths
contain any OS-specific syntax in them, an exception will be thrown.

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 directory

B<Required> - A string path to a directory which will serve as root. The
directory must already exist when the object is built.


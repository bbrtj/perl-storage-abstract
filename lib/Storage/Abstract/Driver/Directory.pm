package Storage::Abstract::Driver::Directory;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);

extends 'Storage::Abstract::Driver';

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

	open my $fh, '>', $name
		or Storage::Abstract::X::StorageError->raise("$name: $!");

	print {$fh} $self->slurp_handle($handle);

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
			mtime => $stat[9],
		);
	}

	open my $fh, '<', $name
		or Storage::Abstract::X::StorageError->raise("$name: $!");

	return $fh;
}

sub dispose_impl
{
	my ($self, $name) = @_;

	unlink $name
		or Storage::Abstract::X::StorageError->raise("$name: $!");
}

1;

__END__


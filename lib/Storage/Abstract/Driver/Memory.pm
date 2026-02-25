package Storage::Abstract::Driver::Memory;

use v5.14;
use warnings;

use Mooish::Base -standard;

use constant TYPE_FILE => 1;
use constant TYPE_DIR => 2;

extends 'Storage::Abstract::Driver';

has field 'files' => (
	isa => HashRef,
	default => sub { {} },
);

with 'Storage::Abstract::Role::Driver::Basic';

sub _access_file
{
	my ($self, $name, $new_value) = @_;
	my @parts = $self->split_path($name);
	my $has_new_value = @_ > 2;

	my $current = $self->files;
	return {
		type => TYPE_DIR,
		files => $current,
	} if !@parts;

	my $filename = pop @parts;
	foreach my $part (@parts) {
		if (!defined $current->{$part}) {
			return undef unless $has_new_value;
			$current->{$part} = {
				type => TYPE_DIR,
				files => {},
			};
		}

		if ($current->{$part}{type} != TYPE_DIR) {
			return undef unless $has_new_value;

			Storage::Abstract::X::StorageError->raise(
				"part $part of path $name already exists as a file"
			);
		}

		$current = $current->{$part}{files};
	}

	if ($has_new_value) {
		if (defined $new_value) {
			$current->{$filename} = $new_value;
		}
		else {
			delete $current->{$filename};
		}
	}

	return $current->{$filename};
}

sub _list
{
	my ($self, $prefix, $dir, %opts) = @_;
	my @files = keys %{$dir};

	my @directories = grep { $dir->{$_} && $dir->{$_}{type} == TYPE_DIR } @files;

	my @results = grep { /$opts{filter_re}/ } $opts{directories}
		? @directories
		: grep { $dir->{$_} && $dir->{$_}{type} == TYPE_FILE } @files
		;

	push @results, map { $self->_list($_, $dir->{$_}{files}, %opts) } @directories
		if $opts{recursive};

	return map { $self->join_path($prefix, $_) } @results;
}

sub store_impl
{
	my ($self, $name, $handle) = @_;
	my $files = $self->files;

	my $stored = $self->_access_file($name);

	Storage::Abstract::X::StorageError->raise(
		'object already exists as a directory'
	) if $stored && $stored->{type} != TYPE_FILE;

	$stored = $self->_access_file(
		$name, {
			type => TYPE_FILE,
			content => undef,
			properties => $self->common_properties($handle),
		}
	);

	open my $fh, '>:raw', \$stored->{content}
		or Storage::Abstract::X::StorageError->raise("Could not open storage: $!");

	tied(*$handle)->copy($fh);

	close $fh
		or Storage::Abstract::X::StorageError->raise("Could not close handle: $!");
}

sub is_stored_impl
{
	my ($self, $name, %opts) = @_;
	my $type = $opts{directory} ? TYPE_DIR : TYPE_FILE;

	my $stored = $self->_access_file($name);
	return defined $stored && $stored->{type} == $type;
}

sub retrieve_impl
{
	my ($self, $name, $properties) = @_;
	my $stored = $self->_access_file($name);

	if ($properties) {
		%{$properties} = %{$stored->{properties}};
	}

	return Storage::Abstract::Handle->adapt(\$stored->{content});
}

sub dispose_impl
{
	my ($self, $name, %opts) = @_;
	my $type = $opts{directory} ? TYPE_DIR : TYPE_FILE;

	my $file = $self->_access_file($name);

	Storage::Abstract::X::StorageError->raise(
		'object type mismatch - not a ' . ($opts{directory} ? 'directory' : 'file')
	) if $file->{type} != $type;

	Storage::Abstract::X::StorageError->raise(
		'directory is not empty'
	) if $opts{directory} && keys %{$file->{files}} > 0;

	$self->_access_file($name, undef);
}

sub list_impl
{
	my ($self, $directory, %opts) = @_;

	my $stored_dir = $self->_access_file($directory);

	Storage::Abstract::X::NotFound->raise(
		'directory does not exist'
	) unless $stored_dir;

	Storage::Abstract::X::StorageError->raise(
		'object type mismatch - not a directory'
	) unless $stored_dir->{type} == TYPE_DIR;

	$opts{filter_re} = quotemeta $opts{filter};
	$opts{filter_re} =~ s{\\\*}{.*}g;
	$opts{filter_re} = qr{^ $opts{filter_re} $}x;

	return [
		map { $self->resolve_path($_) }
			$self->_list($directory, $stored_dir->{files}, %opts)
	];
}

1;

__END__

=head1 NAME

Storage::Abstract::Driver::Memory - In-memory storage of files

=head1 SYNOPSIS

	my $storage = Storage::Abstract->new(
		driver => 'memory',
	);

=head1 DESCRIPTION

This driver will store entire files in Perl process memory. As such, it is most
suitable to use for testing or as a cache of small files.

=head2 Using as a snapshot of a directory

If you want to store just a couple of known files faster than direct disk
access, you can make use of dynamic C<readonly>:

	$storage->set_readonly(0);
	$storage->store('path1', 'file1');
	$storage->store('path2', 'file2');
	$storage->set_readonly(1);

=head1 CUSTOM INTERFACE

=head2 Attributes

=head3 files

The internal structure (hash) holding the files. It cannot be set via the
constructor. It's not recommended to modify it by hand.


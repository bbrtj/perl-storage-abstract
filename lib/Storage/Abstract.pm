package Storage::Abstract;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

has param 'driver' => (
	coerce => (InstanceOf ['Storage::Abstract::Driver'])
		->plus_coercions(HashRef, q{ Storage::Abstract->load_driver($_) }),
	handles => [
		qw(
			store
			is_stored
			retrieve
		)
	],
);

around BUILDARGS => sub {
	my ($orig, $self, @args) = @_;

	return $self->$orig(@args)
		unless @args % 2 == 0;

	return $self->$orig(
		driver => {@args},
	);
};

sub load_driver
{
	my ($class, $args) = @_;
	my $name = ucfirst(delete $args->{driver} // 'Directory');
	my $full_namespace = "Storage::Abstract::Driver::$name";

	(my $file_path = $full_namespace) =~ s{::}{/}g;
	require "$file_path.pm";
	return $full_namespace->new($args);
}

1;

__END__

=head1 NAME

Storage::Abstract - Abstraction for file storage

=head1 SYNOPSIS

	use Storage::Abstract;

	my $storage = Storage::Abstract->new(
		driver => 'Directory',
		directory => '/my/directory',
	);

	$storage->store('some/file', $fh);
	my $fh = $storage->retrieve('some/file', \my %info);


=head1 DESCRIPTION

This module lets you store and retrieve files from various places with a
unified API.

=head1 SEE ALSO

L<Some::Module>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


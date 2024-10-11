package Storage::Abstract;

use v5.14;
use warnings;

1;

__END__

=head1 NAME

Storage::Abstract - Abstraction for file storage

=head1 SYNOPSIS

	use Storage::Abstract;

	my $storage = Storage::Abstract->new(
		driver => 'LocalDirectory',
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


use Test2::V0;
use Storage::Abstract;
use Data::Dumper;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the composite driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'composite',
	sources => [
		{
			driver => 'directory',
			directory => 't/testfiles',
			readonly => !!1,
		},
		{
			driver => 'Memory',
		},
	],
);

ok $storage->is_stored('wiki.html'), 'wiki.html stored ok';
ok $storage->is_stored('utf8.txt'), 'utf8 stored ok';
ok !$storage->is_stored('foo'), 'foo not stored ok';

ok lives {
	$storage->store('foo', get_testfile_handle);
	ok $storage->is_stored('foo'), 'foo stored ok';
} or diag(Dumper($storage->driver->errors));

ok !$storage->driver->sources->[0]->is_stored('foo'), 'not stored in readonly driver ok';
ok $storage->driver->sources->[1]->is_stored('foo'), 'stored in memory driver ok';

is slurp_handle($storage->retrieve('foo')), slurp_handle($storage->retrieve('wiki.html')), 'new file ok';

done_testing;


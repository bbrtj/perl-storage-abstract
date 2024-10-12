use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests whether it's impossible to store in a readonly driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
	readonly => 1,
);

my $fh = get_testfile_handle;

my $err = dies {
	$storage->store('some/file', $fh);
};

isa_ok $err, 'Storage::Abstract::X::StorageError';
like $err, qr/is readonly/;

done_testing;


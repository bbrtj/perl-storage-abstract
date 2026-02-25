use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the memory driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

test_basic_driver($storage);

done_testing;


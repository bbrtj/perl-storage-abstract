use Test2::V0;
use Storage::Abstract;
use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the directory driver
################################################################################

my $dir = tempdir();
my $storage = Storage::Abstract->new(
	driver => 'directory',
	directory => $dir,
);

test_basic_driver($storage);

done_testing;


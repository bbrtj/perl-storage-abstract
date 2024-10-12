use Test2::V0;
use Storage::Abstract;
use File::Temp qw(tempdir);

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

my $fh = get_testfile_handle;

$storage->store('/some/file', $fh);
ok $storage->is_stored('/some/file'), 'stored file 1 ok';

$storage->store('/some/other/file', $fh);
ok $storage->is_stored('/some/file'), 'stored file 2 ok';

my $fh2 = $storage->retrieve('/some/other/file', \my %info);

is slurp_handle($fh2), slurp_handle($fh), 'content ok';
is $info{mtime}, within(time, 3), 'mtime ok';

$storage->dispose('/some/file');
ok !$storage->is_stored('/some/file'), 'foo disposed ok';

done_testing;


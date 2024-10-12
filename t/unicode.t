use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests whether unicode is properly ignored
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

my $fh = get_testfile_handle('utf8.txt');

$storage->store('some/file', $fh);
my $fh2 = $storage->retrieve('some/file');

my $content = slurp_handle($fh2);
is $content, slurp_handle($fh), 'unicode content ok';
unlike $content, qr/zażółć/, 'not unicode ok';

# now slurp using proper binmode
binmode $fh2, ':encoding(UTF-8)';
my $content_decoded = slurp_handle($fh2);
like $content_decoded, qr/zażółć/, 'unicode ok';

done_testing;


use Test2::V0;
use Storage::Abstract;

################################################################################
# This tests whether basic store / retrieve function works on in-memory driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

my $content = "test file\nline2\nline3\n\n";
open my $fh, '<', \$content
	or die "could not open file handle from scalar: $!";

$storage->store('some/file', $fh);
my $fh2 = $storage->retrieve('some/file', \my %info);

my $content2 = do {
	local $/;
	readline $fh2;
};

is $content2, $content, 'content ok';

done_testing;


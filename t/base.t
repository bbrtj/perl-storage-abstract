use Test2::V0;
use Storage::Abstract;

################################################################################
# This tests whether basic store / retrieve function works on in-memory driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

# test "file"
my $content = "test file\nline2\nline3\n\n";
open my $fh, '<', \$content
	or die "could not open file handle from scalar: $!";

# store + retrieve
$storage->store('some/file', $fh);
is $storage->is_stored('some/file'), T(), 'is_stored ok';
my $fh2 = $storage->retrieve('some/file', \my %info);

# slurp the result
my $content2 = do {
	local $/;
	readline $fh2;
};

# Same "file"? Modification time within 3 second tolerance?
is $content2, $content, 'content ok';
is $info{mtime}, within(time, 3), 'mtime ok';

done_testing;


use Test2::V0;
use Storage::Abstract;

################################################################################
# This tests whether you can store in a readonly driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
	readonly => 1,
);

# test "file"
my $content = "test file\nline2\nline3\n\n";
open my $fh, '<', \$content
	or die "could not open file handle from scalar: $!";

my $err = dies {
	$storage->store('some/file', $fh);
};

isa_ok $err, 'Storage::Abstract::X::StorageError';
like $err, qr/is readonly/;

done_testing;


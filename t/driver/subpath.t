use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests the subpath driver
################################################################################

my $nested_storage = Storage::Abstract->new(
	driver => 'memory',
);

my $storage = Storage::Abstract->new(
	driver => 'subpath',
	subpath => '/foo',
	source => $nested_storage,
);

$nested_storage->store('foo1', \'foo');
$nested_storage->store('foo/bar1', \'bar');
$nested_storage->store('foo/bar/baz1', \'baz');

ok $storage->is_stored('bar', directory => !!1), 'directory stored ok';
ok $storage->is_stored('bar/baz1'), 'baz stored ok';
is slurp_handle($storage->retrieve('bar/baz1', \my %info)), 'baz', 'baz content ok';
is $info{mtime}, within(time, 3), 'mtime ok';
is $info{size}, 3, 'size ok';

$storage->store('foo1', \'foo2');
ok $nested_storage->is_stored('foo/foo1'), 'nested foo stored ok';

is $storage->list(undef, recursive => !!1), bag {
	item 'foo1';
	item 'bar1';
	item 'bar/baz1';

	end();
}, 'file list ok';

$storage->dispose('foo1');
ok !$storage->is_stored('foo1'), 'nested foo disposed ok';

done_testing;


use Test2::V0;
use Storage::Abstract;

################################################################################
# This tests the relay driver
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'relay',
	sources => [
		{
			driver => 'Memory',
		},
	],
);

# TODO
is $storage->is_stored('sth'), F(), 'is_stored ok';

done_testing;


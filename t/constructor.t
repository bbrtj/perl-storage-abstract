use Test2::V0;
use Storage::Abstract;
use Storage::Abstract::Driver::Memory;

################################################################################
# This tests whether constructor works as expected
################################################################################

my $driver = Storage::Abstract::Driver::Memory->new;

subtest 'should construct using hash' => sub {
	my $storage = Storage::Abstract->new(
		driver => $driver,
	);

	is $storage->driver, $driver, 'driver ok';
};

subtest 'should construct using hash reference' => sub {
	my $storage = Storage::Abstract->new(
		{
			driver => $driver,
		}
	);

	is $storage->driver, $driver, 'driver ok';
};

done_testing;


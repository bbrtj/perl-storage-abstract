#!/usr/bin/env perl

use v5.14;
use warnings;

use Benchmark qw(cmpthese);

use lib 'lib';

use Storage::Abstract;

my $storage = Storage::Abstract->new(
	driver => 'composite',
	source => [
		{
			driver => 'superpath',
			source => {
				driver => 'memory',
			},
			superpath => 'test',
		},
		{
			driver => 'memory',
		}
	],
);

$storage->store('/test/abc', \"abcdef\nghijkl");
$storage->driver->source->[0]->driver->source->set_readonly(!!1);
$storage->refresh;

cmpthese - 3, {
	store => sub {
		$storage->store('/test2/abc', \'abcdef');
	},
	retrieve => sub {
		$storage->retrieve('/test/abc');
	},
	read => sub {
		my $handle = $storage->retrieve('/test/abc');
		while (my $line = readline $handle) { }
	},
};


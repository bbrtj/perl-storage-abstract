package Storage::Abstract::Role::Driver;

use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use Moo::Role;

has param 'readonly' => (
	writer => 1,
	isa => Bool,
	default => !!0,
);

1;


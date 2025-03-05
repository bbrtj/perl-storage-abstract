package Storage::Abstract::Role::Driver::Basic;

use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use Moo::Role;

sub _build_readonly
{
	return !!0;
}

before 'store_impl' => sub {
	if (ref $_[2] ne 'GLOB') {
		Storage::Abstract::X::HandleError->raise('handle argument is not defined')
			unless defined $_[2];

		$_[2] = $_[0]->open_handle($_[2]);
	}
};

before ['retrieve_impl', 'dispose_impl'] => sub {
	Storage::Abstract::X::NotFound->raise("file was not found")
		unless $_[0]->is_stored_impl($_[1]);
};

1;


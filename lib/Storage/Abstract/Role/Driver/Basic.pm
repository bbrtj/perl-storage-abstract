package Storage::Abstract::Role::Driver::Basic;

use v5.14;
use warnings;

use Mooish::Base -standard, -role;

use Storage::Abstract::Handle;

sub _build_readonly
{
	return !!0;
}

before 'store_impl' => sub {
	$_[2] = Storage::Abstract::Handle->adapt($_[2]);
};

before 'retrieve_impl' => sub {
	Storage::Abstract::X::NotFound->raise('file was not found')
		unless $_[0]->is_stored_impl($_[1]);
};

before 'dispose_impl' => sub {
	my $self = shift;

	Storage::Abstract::X::NotFound->raise('file was not found')
		unless $self->is_stored_impl(@_);
};

1;


package Storage::Abstract::X;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common -types;

use overload
	q{""} => "as_string",
	fallback => 1;

has param 'message' => (
	isa => Str,
	writer => -hidden,
);

has field 'caller' => (
	default => sub {
		for my $call_level (1 .. 10) {
			my @data = caller $call_level;
			return \@data
				if $data[1] !~ /^\(eval/ && $data[0] !~ /^Storage::Abstract/;
		}
		return undef;
	},
);

sub raise
{
	my ($self, $error) = @_;

	if (defined $error) {
		$self = $self->new(message => $error);
	}

	die $self;
}

sub as_string
{
	my ($self) = @_;

	my $raised = $self->message;
	$raised =~ s/\s+\z//;

	if (my $caller = $self->caller) {
		$raised .= ' (raised at ' . $caller->[1] . ', line ' . $caller->[2] . ')';
	}

	my $class = ref $self;
	my $pkg = __PACKAGE__;
	$class =~ s/${pkg}:://;

	return "Storage::Abstract exception: [$class] $raised";
}

## SUBCLASSES

package Storage::Abstract::X::NotFound {
	use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::PathError {
	use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::HandleError {
	use parent -norequire, 'Storage::Abstract::X';
}

package Storage::Abstract::X::StorageError {
	use parent -norequire, 'Storage::Abstract::X';
}

1;

__END__


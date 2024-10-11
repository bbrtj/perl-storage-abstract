package Storage::Abstract::X;

use v5.14;
use warnings;

use Moo;
use Mooish::AttributeBuilder;
use Types::Common -types;

use overload
	q{""} => "as_string",
	fallback => 1;

has param 'message' => (
	isa => Str,
	writer => -hidden,
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

	my $class = ref $self;
	my $pkg = __PACKAGE__;
	$class =~ s/${pkg}:://;

	return "Storage error: [$class] $raised";
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

1;

__END__


package Storage::Abstract::Handle;

use v5.14;
use warnings;

use Carp qw();
use Scalar::Util qw();
use Storage::Abstract::X;

use parent 'Tie::Handle';

sub copy
{
	my ($self, $handle_to) = @_;

	# no extra behavior of print
	local $\;

	my $read = sub { $self->READ($_[0], 8 * 1024) };
	my $write = sub { print {$handle_to} $_[0] };

	# can use sysread / syswrite?
	if (fileno $self->{handle} != -1 && fileno $handle_to != -1) {
		$read = sub { sysread $self->{handle}, $_[0], 128 * 1024 };
		$write = sub {
			my $written = 0;
			while ($written < $_[1]) {
				my $res = syswrite $handle_to, $_[0], $_[1], $written;
				return undef unless defined $res;
				$written += $res;
			}

			return 1;
		};
	}

	my $buffer;
	while ('copying') {
		my $bytes = $read->($buffer);

		Storage::Abstract::X::HandleError->raise("error reading from handle: $!")
			unless defined $bytes;
		last if $bytes == 0;
		$write->($buffer, $bytes)
			or Storage::Abstract::X::StorageError->raise("error during file copying: $!");
	}
}

sub size
{
	my ($self) = @_;

	my $handle = $self->{handle};
	my $size;

	if (fileno $handle == -1) {
		my $success = (my $pos = tell $handle) >= 0;
		$success &&= seek $handle, 0, 2;
		$success &&= ($size = tell $handle) >= 0;
		$success &&= seek $handle, $pos, 0;

		$success or Storage::Abstract::X::HandleError->raise($!);
	}
	else {
		$size = -s $handle;
	}

	return $size;
}

sub adapt
{
	my ($class, $arg) = @_;

	return $arg if Scalar::Util::blessed $arg && $arg->isa($class);

	my $fh = \do { local *HANDLE };
	tie *$fh, $class, $arg;

	return $fh;
}

sub TIEHANDLE
{
	my ($class, $handle) = @_;

	if (ref $handle ne 'GLOB') {
		my $arg = $handle;
		undef $handle;

		open $handle, '<:raw', $arg
			or Storage::Abstract::X::HandleError->raise((ref $arg ? '' : "$arg: ") . $!);
	}

	return bless {
		handle => $handle,
	}, $class;
}

sub WRITE
{
	Carp::croak 'Handle is readonly';
}

sub EOF
{
	my $self = shift;

	return eof $self->{handle};
}

sub FILENO
{

	# the main handle cannot have real fileno, since only the underlying
	# handle can be a real file handle
	return -1;
}

sub BINMODE
{
	my $self = shift;

	return &CORE::binmode($self->{handle}, @_);
}

sub TELL
{
	my $self = shift;

	return tell $self->{handle};
}

sub SEEK
{
	my $self = shift;

	return &CORE::seek($self->{handle}, @_);
}

sub READLINE
{
	my $self = shift;

	return readline $self->{handle};
}

sub READ
{
	my $self = shift;

	return &CORE::read($self->{handle}, \$_[0], @_[1 .. $#_]);
}

sub CLOSE
{
	my $self = shift;

	return close $self->{handle};
}

1;


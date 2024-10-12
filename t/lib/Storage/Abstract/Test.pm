package Storage::Abstract::Test;

use v5.14;
use warnings;

use Storage::Abstract::Driver;
use File::Spec;

use Exporter qw(import);
our @EXPORT = qw(
	get_testfile
	get_testfile_handle
	slurp_handle
);

my @testdir = qw(t testfiles);

sub get_testfile
{
	my ($name) = @_;
	$name //= 'page.html';

	return File::Spec->catdir(@testdir, $name);
}

sub get_testfile_handle
{
	my ($name) = @_;

	my $file = get_testfile($name);
	open my $fh, '<', $file
		or die "$file error: $!";

	return $fh;
}

sub slurp_handle
{
	my ($fh) = @_;

	return Storage::Abstract::Driver->slurp_handle($fh);
}

1;


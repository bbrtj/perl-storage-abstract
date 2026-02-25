package Storage::Abstract::Test;

use v5.14;
use warnings;

use File::Spec;
use Test2::V0;

use Exporter qw(import);
our @EXPORT = qw(
	get_testfile
	get_testfile_size
	get_testfile_handle
	slurp_handle
	test_basic_driver
);

my @testdir = qw(t testfiles);

sub get_testfile
{
	my ($name) = @_;
	$name //= 'page.html';

	return File::Spec->catdir(@testdir, $name);
}

sub get_testfile_size
{
	my ($name) = @_;

	my $file = get_testfile($name);
	return -s $file;
}

sub get_testfile_handle
{
	my ($name) = @_;

	my $file = get_testfile($name);
	open my $fh, '<:raw', $file
		or die "$file error: $!";

	return $fh;
}

sub slurp_handle
{
	my ($fh) = @_;
	seek $fh, 0, 0;

	my $slurped = do {
		local $/;
		readline $fh;
	};

	die $! || 'no error - handle EOF?'
		unless defined $slurped;

	return $slurped;
}

sub test_basic_driver
{
	my ($storage) = @_;

	subtest 'should store files' => sub {
		$storage->store('some/file', get_testfile_handle);
		ok $storage->is_stored('some/file'), 'stored file 1 ok';

		$storage->store('other/file', get_testfile);
		ok $storage->is_stored('other/file'), 'stored file 2 ok';
	};

	subtest 'should not override directories with files' => sub {
		isa_ok dies {
			$storage->store('/some', \'test');
		}, 'Storage::Abstract::X::StorageError';
	};

	subtest 'should retrieve files' => sub {
		my $fh = $storage->retrieve('some/file', \my %info);

		is slurp_handle($fh), slurp_handle(get_testfile_handle), 'content ok';
		is $info{mtime}, within(time, 3), 'mtime ok';
		is $info{size}, get_testfile_size, 'size ok';
	};

	subtest 'should not dispose non-empty directories' => sub {
		isa_ok dies {
			$storage->dispose('/some', directory => !!1);
		}, 'Storage::Abstract::X::StorageError';

		ok $storage->is_stored('/some', directory => !!1), 'directory not disposed ok';
	};

	subtest 'should dispose files' => sub {
		ok $storage->is_stored('/some/file'), 'file stored ok';
		$storage->dispose('/some/file');
		ok !$storage->is_stored('/some/file'), 'file disposed ok';
	};

	subtest 'should dispose directories' => sub {
		ok $storage->is_stored('/some', directory => !!1), 'directory stored ok';
		$storage->dispose('/some/', directory => !!1);
		ok !$storage->is_stored('/some', directory => !!1), 'directory disposed ok';
	};

	subtest 'should not retrieve unknown files' => sub {
		isa_ok dies {
			$storage->retrieve('unknownfile');
		}, 'Storage::Abstract::X::NotFound';
	};

	subtest 'should not dispose unknown files' => sub {
		isa_ok dies {
			$storage->dispose('unknownfile');
		}, 'Storage::Abstract::X::NotFound';
	};

	# add empty files for listing
	$storage->store('/dir1/a', \'');
	$storage->store('/dir1/a.txt', \'');
	$storage->store('/dir1/aa.txt', \'');
	$storage->store('/dir1/ba.txt', \'');
	$storage->store('/dir1/dir11/a.txt', \'');
	$storage->store('/dir2/a.txt', \'');

	subtest 'should list all root files' => sub {
		is $storage->list(undef), bag {
			end();
		},
			'file list ok';

		is $storage->list(undef, recursive => !!1), bag {
			item 'other/file';
			item 'dir1/a';
			item 'dir1/a.txt';
			item 'dir1/aa.txt';
			item 'dir1/ba.txt';
			item 'dir1/dir11/a.txt';
			item 'dir2/a.txt';

			end();
		},
			'recursive file list ok';
	};

	subtest 'should list directories' => sub {
		is $storage->list(undef, directories => !!1), bag {
			item 'dir1';
			item 'dir2';
			item 'other';

			end();
		},
			'directory list ok';

		is $storage->list(undef, recursive => !!1, directories => !!1), bag {
			item 'other';
			item 'dir1';
			item 'dir1/dir11';
			item 'dir2';

			end();
		},
			'recursive directory list ok';
	};

	subtest 'should list files in a directory' => sub {
		is $storage->list('dir1'), bag {
			item 'dir1/a';
			item 'dir1/a.txt';
			item 'dir1/aa.txt';
			item 'dir1/ba.txt';

			end();
		},
			'file list ok';

		is $storage->list('dir1', recursive => !!1), bag {
			item 'dir1/a';
			item 'dir1/a.txt';
			item 'dir1/aa.txt';
			item 'dir1/ba.txt';
			item 'dir1/dir11/a.txt';

			end();
		},
			'recursive file list ok';
	};

	subtest 'should list files in a directory with filter' => sub {
		is $storage->list('dir1', filter => 'a.txt'), bag {
			item 'dir1/a.txt';

			end();
		},
			'file list ok';

		is $storage->list('dir1', recursive => !!1, filter => 'a.txt'), bag {
			item 'dir1/a.txt';
			item 'dir1/dir11/a.txt';

			end();
		},
			'recursive file list ok';
	};

	subtest 'should list directories with filter' => sub {
		is $storage->list('/', filter => 'dir*', directories => !!1, recursive => !!1), bag {
			item 'dir1';
			item 'dir1/dir11';
			item 'dir2';

			end();
		},
			'directory list ok';
	};

	subtest 'should list files in a directory with wildcard' => sub {
		is $storage->list('dir1', filter => 'a*.txt'), bag {
			item 'dir1/a.txt';
			item 'dir1/aa.txt';

			end();
		},
			'file list ok';

		is $storage->list('dir1', recursive => !!1, filter => 'a*.txt'), bag {
			item 'dir1/a.txt';
			item 'dir1/aa.txt';
			item 'dir1/dir11/a.txt';

			end();
		},
			'recursive file list ok';
	};

	subtest 'should cover list edge cases' => sub {
		isa_ok dies {
			$storage->list('dir1/a.txt');
		}, ['Storage::Abstract::X::StorageError'], 'list file ok';

		isa_ok dies {
			$storage->list('unknowndir');
		}, ['Storage::Abstract::X::NotFound'], 'list non-existent directory ok';

		ok $storage->is_stored('/', directory => !!1), 'root stored as a directory ok';
	};
}

1;


use strict;
use warnings;

use Test::Spec;

# rcopy_glob
# rmove_glob

use File::Path;
use File::Temp;
use File::Find;
use Path::Tiny;

use File::Copy::Recursive;

use constant max_mode => 0777;

sub establish_tree {
    my ($dir) = @_;

    File::Path::make_path ($dir . "/subdir1/subdir2");

    Path::Tiny::path ($dir . "/subdir1")->chmod (0777);
    Path::Tiny::path ($dir . "/subdir1/subdir2")->chmod (0744);

    Path::Tiny::path ($dir . "/data.txt")->spew ("text1 text2 text3 text4");
    Path::Tiny::path ($dir . "/data.txt")->chmod (0777);

    Path::Tiny::path ($dir . "/data1.txt")->spew ("text1 text2 text3 text4 text6");
    Path::Tiny::path ($dir . "/data1.txt")->chmod (0777);

    Path::Tiny::path ($dir . "/data.lines")->spew ('text1 text2');
    Path::Tiny::path ($dir . "/data.lines")->chmod (0666);

    Path::Tiny::path ($dir . "/subdir1/data.txt")->spew ('text1 text2 text3 text4 text5');
    Path::Tiny::path ($dir . "/subdir1/data.txt")->chmod(0644);
    Path::Tiny::path ($dir . "/subdir1/data.lines")->spew ('text1 text2 text3 text4 text5 text6');
    Path::Tiny::path ($dir . "/subdir1/data.lines")->chmod(0600);
    Path::Tiny::path ($dir . "/subdir1/.hidden")->spew ('text1 text2 text3');
    Path::Tiny::path ($dir . "/subdir1/.hidden")->chmod(0644);

    Path::Tiny::path ($dir . "/subdir1/subdir2/data.txt")->spew ('text1 text2 text3 another line');
    Path::Tiny::path ($dir . "/subdir1/subdir2/data.txt")->chmod(0644);
    Path::Tiny::path ($dir . "/subdir1/subdir2/data.lines")->spew ('text1 text2 text3 more lines');
    Path::Tiny::path ($dir . "/subdir1/subdir2/data.lines")->chmod(0644);
    Path::Tiny::path ($dir . "/subdir1/subdir2/.hidden")->spew ('text1 text2 text3 more and more');
    Path::Tiny::path ($dir . "/subdir1/subdir2/.hidden")->chmod(0644);

    return;
}

sub _get_mode {
    my ($node) = @_;
    return ((stat ($node))[2] & max_mode);
}

sub get_normalized_tree {
    my ($dir) = @_;

    my @output;

    File::Find::find (sub {
        my $file = $File::Find::name;
        my $type = 'FILE';
        $type = 'DIR' if -d $file;
        my $mode = _get_mode ($file);
        my $normalized_file = $file;
        $normalized_file =~ s:^$dir::;
        $normalized_file = '/' if $normalized_file eq '';
        my $str = sprintf ("%s,%s,%0o", $normalized_file, $type, $mode);
        $str .= ',' . Path::Tiny::path ($file)->digest () . ',' . -s $file if -f $file;
        push (@output, $str);
    }, $dir);

    return sort @output;
}

describe "directory trees" => sub {
    share my %conf;

    around {
        my $source_dir = File::Temp->newdir ();
        my $target_dir = File::Temp->newdir ();

        $conf{source_dir} = $source_dir;
        $conf{target_dir} = $target_dir;

        establish_tree ($source_dir);

        yield;
    };

    it "should have established tree correctly" => sub {
        my @tree = get_normalized_tree ($conf{source_dir});

        my $expected_ar = [
			'/,DIR,700',
			'/data.lines,FILE,666,32966ae14c16791dd85fc36abe2dbeb20a91a4bd2dbd596ce78c66192a0b8594,11',
			'/data.txt,FILE,777,d5ada2b398eb5e016ca7e09e6097af14e5a8cf921283337c19eb6ae15a4336e2,23',
			'/data1.txt,FILE,777,11a96bd1d4f84bfb45e747c4d47e5b5b67965684c99ac44e90aff9e62e8522b3,29',
			'/subdir1,DIR,777',
			'/subdir1/.hidden,FILE,644,b4216652c25efe673235df3cc64615e9f73d3e5c59d41b8deae70fc3b1407718,17',
			'/subdir1/data.lines,FILE,600,cce57f193258c0af2bda214003577b26316ee21781495d906689a2e01377cd53,35',
			'/subdir1/data.txt,FILE,644,6b5379f304f65d3dc71fdd174d40a1737eeb63d9fb0f81351213113e7ee1e1b4,29',
			'/subdir1/subdir2,DIR,744',
			'/subdir1/subdir2/.hidden,FILE,644,2a1716576c42bf0e390dd65df132075bca8859f2f33fe3507ad2b52c3e45e15d,31',
			'/subdir1/subdir2/data.lines,FILE,644,302446b857a36ab83a68b312ee31160e87d14e4766320076102decdcafe2b589,28',
			'/subdir1/subdir2/data.txt,FILE,644,0a0873978b0495bd6f044778c8f22cd7fe42b3853248ee417bc72c60dffcf7c3,30',
        ];

        cmp_deeply (\@tree, $expected_ar);
    };

	it "fcopy should copy one file, contents and mode" => sub {
		File::Copy::Recursive::fcopy ($conf{source_dir} . '/data.lines', $conf{target_dir} . '/data.lines');

        my @tree = get_normalized_tree ($conf{target_dir});

        my $expected_ar = [
			'/,DIR,700',
			'/data.lines,FILE,666,32966ae14c16791dd85fc36abe2dbeb20a91a4bd2dbd596ce78c66192a0b8594,11',
        ];

        cmp_deeply (\@tree, $expected_ar);
	};

	it "dircopy should copy entire directory, contents and modes" => sub {
		File::Copy::Recursive::dircopy ($conf{source_dir}, $conf{target_dir});

        my @source_tree = get_normalized_tree ($conf{source_dir});
        my @target_tree = get_normalized_tree ($conf{target_dir});

        cmp_deeply (\@target_tree, \@source_tree);
	};

	it "rcopy should copy one file, contents and mode" => sub {
		File::Copy::Recursive::rcopy ($conf{source_dir} . '/data.lines', $conf{target_dir} . '/data.lines');

        my @tree = get_normalized_tree ($conf{target_dir});

        my $expected_ar = [
			'/,DIR,700',
			'/data.lines,FILE,666,32966ae14c16791dd85fc36abe2dbeb20a91a4bd2dbd596ce78c66192a0b8594,11',
        ];

        cmp_deeply (\@tree, $expected_ar);
	};

	it "rcopy should copy entire directory, contents and modes" => sub {
		File::Copy::Recursive::rcopy ($conf{source_dir}, $conf{target_dir});

        my @source_tree = get_normalized_tree ($conf{source_dir});
        my @target_tree = get_normalized_tree ($conf{target_dir});

        cmp_deeply (\@target_tree, \@source_tree);
	};

	it "rmove should move entire directory, contents and modes" => sub {
        my @source_tree = get_normalized_tree ($conf{source_dir});

		File::Copy::Recursive::rmove ($conf{source_dir}, $conf{target_dir});

        my @target_tree = get_normalized_tree ($conf{target_dir});

        cmp_deeply (\@target_tree, \@source_tree);
	};

	it "rmove should move entire directory, removing source_dir" => sub {
		File::Copy::Recursive::rmove ($conf{source_dir}, $conf{target_dir});

		ok (!-d $conf{source_dir});
	};

	it "fmove should move one file, contents and mode" => sub {
		File::Copy::Recursive::fmove ($conf{source_dir} . '/data.lines', $conf{target_dir} . '/data.lines');

        my @target_tree = get_normalized_tree ($conf{target_dir});

		my $lines = '/data.lines,FILE,666,32966ae14c16791dd85fc36abe2dbeb20a91a4bd2dbd596ce78c66192a0b8594,11';

		is ($target_tree [1], $lines);
	};

	it "fmove should move one file, removing it from the source_dir" => sub {
		File::Copy::Recursive::fmove ($conf{source_dir} . '/data.lines', $conf{target_dir} . '/data.lines');

		ok (!-e $conf{source_dir} . '/data.lines');
	};

	it "dirmove should move entire directory, contents and modes" => sub {
        my @source_tree = get_normalized_tree ($conf{source_dir});

		File::Copy::Recursive::dirmove ($conf{source_dir}, $conf{target_dir});

        my @target_tree = get_normalized_tree ($conf{target_dir});

        cmp_deeply (\@target_tree, \@source_tree);
	};

	it "dirmove should move entire directory, removing source_dir" => sub {
		File::Copy::Recursive::dirmove ($conf{source_dir}, $conf{target_dir});

		ok (!-d $conf{source_dir});
	};

	it "rmove_glob should move selected directory contents and modes" => sub {
		File::Copy::Recursive::rmove_glob ($conf{source_dir} . '/*.txt', $conf{target_dir});

        my @target_tree = get_normalized_tree ($conf{target_dir});

		my $expected_ar = [
			'/,DIR,700',
			'/data.txt,FILE,777,d5ada2b398eb5e016ca7e09e6097af14e5a8cf921283337c19eb6ae15a4336e2,23',
			'/data1.txt,FILE,777,11a96bd1d4f84bfb45e747c4d47e5b5b67965684c99ac44e90aff9e62e8522b3,29',
		];

        cmp_deeply (\@target_tree, $expected_ar);
	};

};

runtests unless caller;


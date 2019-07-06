use strict;
use warnings;

use Test::Spec;

use FindBin;
use lib "$FindBin::Bin/..";

use File::Temp;

use Test::MockFile;

use File::Copy::Recursive;

use Utils::FileSystemSupport;

sub _spew_chmod
{
    my ($mock, $mode, $contents) = @_;

    $mock->contents ($contents);
    $mock->chmod ($mode);

    return;
}


sub establish_tree_with_mockfile {
    my ($dir, $include_contents) = @_;

    # the Test::MockFile objects must remain alive to maintain the mocks

    my $hold_mocks_hr = {};

    my $mock_dir     = Test::MockFile->dir ($dir, [ 'subdir1', 'data.lines', 'data.txt', 'data1.txt' ]);
    my $mock_subdir1 = Test::MockFile->dir ($dir . '/subdir1', [ '.hidden', 'subdir2', 'data.lines', 'data.txt' ] );
    my $mock_subdir2 = Test::MockFile->dir ($dir . '/subdir1/subdir2', [ '.hidden', 'data.lines', 'data.txt' ] );

    $hold_mocks_hr->{'mock_dir'} = $mock_dir;
    $hold_mocks_hr->{'mock_subdir1'} = $mock_subdir1;
    $hold_mocks_hr->{'mock_subdir2'} = $mock_subdir2;

    my $mock_data  = Test::MockFile->file ($dir . "/data.txt");
    my $mock_data1 = Test::MockFile->file ($dir . "/data1.txt");

    print "mock_data :" . $mock_data->filename . ":\n";

    $hold_mocks_hr->{'mock_data'} = $mock_data;
    $hold_mocks_hr->{'mock_data1'} = $mock_data1;

    my $mock_data_lines = Test::MockFile->file ($dir . "/data1.lines");

    $hold_mocks_hr->{'mock_data_lines'} = $mock_data_lines;

    my $mock_subdir1_data = Test::MockFile->file ($dir . "/subdir1/data.txt");
    my $mock_subdir1_data_lines = Test::MockFile->file ($dir . "/subdir1/data.lines");
    my $mock_subdir1_hidden = Test::MockFile->file ($dir . "/subdir1/.hidden");

    $hold_mocks_hr->{'mock_subdir1_data'} = $mock_subdir1_data;
    $hold_mocks_hr->{'mock_subdir1_data_lines'} = $mock_subdir1_data_lines;
    $hold_mocks_hr->{'mock_subdir1_hidden'} = $mock_subdir1_hidden;

    my $mock_subdir2_data = Test::MockFile->file ($dir . "/subdir1/subdir2/data.txt");
    my $mock_subdir2_data_lines = Test::MockFile->file ($dir . "/subdir1/subdir2/data.lines");
    my $mock_subdir2_hidden = Test::MockFile->file ($dir . "/subdir1/subdir2/.hidden");

    $hold_mocks_hr->{'mock_subdir2_data'} = $mock_subdir2_data;
    $hold_mocks_hr->{'mock_subdir2_data_lines'} = $mock_subdir2_data_lines;
    $hold_mocks_hr->{'mock_subdir2_hidden'} = $mock_subdir2_hidden;

    if ($include_contents)
    {
        $mock_subdir1->chmod (0777);
        $mock_subdir2->chmod (0744);

        _spew_chmod  ($mock_data, 0777, "text1 text2 text3 text4");
        _spew_chmod  ($mock_data1, 0777, "text1 text2 text3 text4 text6");
        _spew_chmod  ($mock_data_lines, 0666, "text1 text2");

        _spew_chmod  ($mock_subdir1_data, 0644, "text1 text2 text3 text4 text5");
        _spew_chmod  ($mock_subdir1_data_lines, 0600, "text1 text2 text3 text4 text5 text6");
        _spew_chmod  ($mock_subdir1_hidden, 0644, "text1 text2 text3");

        _spew_chmod  ($mock_subdir2_data, 0644, "text1 text2 text3 another line");
        _spew_chmod  ($mock_subdir2_data_lines, 0644, "text1 text2 text3 more lines");
        _spew_chmod  ($mock_subdir2_hidden, 0644, "text1 text2 text3 more and more");
    }

    return $hold_mocks_hr;
}

spec_helper "$FindBin::Bin/../spec_helpers/main_test.pl";

my $count = 0;

describe "directory trees" => sub {
    share my %conf;

    around {
        my $base = $count ++;

        my $source_dir = '/var/tmp/source_dir_' . sprintf ("%03d", $base);;
        my $target_dir = '/var/tmp/target_dir_' . sprintf ("%03d", $base);;

        $conf{source_dir} = $source_dir;
        $conf{target_dir} = $target_dir;

        my $source_hr = establish_tree_with_mockfile ($source_dir, 1);
        my $target_hr = establish_tree_with_mockfile ($target_dir, 0);

        yield;
    };

    it_should_behave_like "base tests";
};

runtests unless caller;


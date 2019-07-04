use strict;
use warnings;

use Test::Spec;

use FindBin;
use lib "$FindBin::Bin/..";

use File::Temp;

use File::Copy::Recursive;

use Utils::FileSystemSupport;

spec_helper "$FindBin::Bin/../spec_helpers/main_test.pl";

describe "directory trees" => sub {
    share my %conf;

    around {
        print "Around OUTER begins\n";

        my $source_dir = File::Temp->newdir ();
        my $target_dir = File::Temp->newdir ();

        $conf{source_dir} = $source_dir;
        $conf{target_dir} = $target_dir;

        Utils::FileSystemSupport::establish_tree ($source_dir);

        print "Around OUTER your test will now run\n";

        yield;   # your test runs here

        # you can run code after yield
        print "Around OUTER has been run\n";
    };

    it_should_behave_like "base tests";

    describe "auxillary test" => sub {
        around {
            print "Around INNER your test will now run\n";

            yield;

            print "Around INNER has been run\n";
        };

        # these are repeat tests, but should show the around stuff

        it "fcopy should copy one file, contents and mode" => sub {
            File::Copy::Recursive::fcopy ($conf{source_dir} . '/data.lines', $conf{target_dir} . '/data.lines');

            my @tree = Utils::FileSystemSupport::get_normalized_tree ($conf{target_dir});

            my $expected_ar = [
                '/,DIR,700',
                '/data.lines,FILE,666,32966ae14c16791dd85fc36abe2dbeb20a91a4bd2dbd596ce78c66192a0b8594,11',
            ];

            cmp_deeply (\@tree, $expected_ar);
        };

        it "dircopy should copy entire directory, contents and modes" => sub {
            File::Copy::Recursive::dircopy ($conf{source_dir}, $conf{target_dir});

            my @source_tree = Utils::FileSystemSupport::get_normalized_tree ($conf{source_dir});
            my @target_tree = Utils::FileSystemSupport::get_normalized_tree ($conf{target_dir});

            cmp_deeply (\@target_tree, \@source_tree);
        };
    };
};

runtests unless caller;


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

    before all => sub {
        print "I am the big before\n";

        my $source_dir = File::Temp->newdir ();
        my $target_dir = File::Temp->newdir ();

        $conf{source_dir} = $source_dir;
        $conf{target_dir} = $target_dir;

        Utils::FileSystemSupport::establish_tree ($source_dir);
    };

    after each => sub {
        print "After is running\n";

        if (-d $conf{target_dir})
        {
            File::Path::rmtree ($conf{target_dir});
        }

        my $target_dir = File::Temp->newdir ();
        $conf{target_dir} = $target_dir;

        Utils::FileSystemSupport::establish_tree ($conf{source_dir});
    };

    it_should_behave_like "base tests";
};

runtests unless caller;


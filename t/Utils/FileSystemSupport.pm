package Utils::FileSystemSupport;

use strict;
use warnings;

use constant max_mode => 0777;

use File::Path;
use File::Find;
use Path::Tiny;

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

sub get_mode {
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
        my $mode = get_mode ($file);
        my $normalized_file = $file;
        $normalized_file =~ s:^$dir::;
        $normalized_file = '/' if $normalized_file eq '';
        my $str = sprintf ("%s,%s,%0o", $normalized_file, $type, $mode);
        $str .= ',' . Path::Tiny::path ($file)->digest () . ',' . -s $file if -f $file;
        push (@output, $str);
    }, $dir);

    return sort @output;
}

1;

__END__



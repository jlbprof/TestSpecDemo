package Utils::FileSystemSupport;

use strict;
use warnings;

use constant max_mode => 0777;

use File::Path;
use File::Find;
use Path::Tiny;

sub _establish_file
{
    my ($fname, $contents, $mode) = @_;

    if (!-e $fname)
    {
        if (open my $fh, '>', $fname)
        {
            print $fh $contents;
            close $fh;
        }
        else
        {
            die "Cannot open $fname";
        }

        chmod $mode, $fname;
    }

    return;
}

# establishes or "reestablishes" a directory tree

sub establish_tree {
    my ($dir) = @_;

    File::Path::make_path ($dir . "/subdir1/subdir2");

    chmod 0777, $dir . "/subdir1";
    chmod 0744, $dir . "/subdir1/subdir2";

    _establish_file ($dir . "/data.txt", "text1 text2 text3 text4", 0777);
    _establish_file ($dir . "/data1.txt", "text1 text2 text3 text4 text6", 0777);
    _establish_file ($dir . "/data.lines", 'text1 text2', 0666);

    _establish_file ($dir . "/subdir1/data.txt", 'text1 text2 text3 text4 text5', 0644);
    _establish_file ($dir . "/subdir1/data.lines", 'text1 text2 text3 text4 text5 text6', 0600);
    _establish_file ($dir . "/subdir1/.hidden", 'text1 text2 text3', 0644);

    _establish_file ($dir . "/subdir1/subdir2/data.txt", 'text1 text2 text3 another line', 0644);
    _establish_file ($dir . "/subdir1/subdir2/data.lines", 'text1 text2 text3 more lines', 0644);
    _establish_file ($dir . "/subdir1/subdir2/.hidden", 'text1 text2 text3 more and more', 0644);

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



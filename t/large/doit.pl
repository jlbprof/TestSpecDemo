#!/usr/bin/perl

use strict;
use warnings;

use File::stat;
use Path::Tiny;

my $max = oct(777);

my $sb = stat ('File-Copy-Recursive.t');

print $sb->mode . "\n";

printf "%05o\n", ($sb->mode & $max);

printf "max %05o %05x %05d\n",
    $max, $max, $max;

Path::Tiny::path ("data.txt")->spew (qw(line1 line2 line3 line4 line5));


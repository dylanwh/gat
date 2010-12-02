#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd;
use Path::Class;

use Gat::Path::Rules;

my $cwd = dir(cwd);

my $path = Gat::Path::Rules->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    gat_dir  => $cwd->subdir('.gat'),
);

is($path->cleanup('/foo'), '/foo');
is($path->cleanup('/foo/../bar/baz/..'), '/bar');

done_testing;


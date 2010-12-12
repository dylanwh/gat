#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Cwd;
use Path::Class;

use Gat::Path;

my $cwd = dir(cwd);

my $path = Gat::Path->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    gat_dir  => $cwd->subdir('.gat'),
);

is($path->cleanup('/foo'), '/foo');
is($path->cleanup('/foo/../bar/baz/..'), '/bar');
is($path->cleanup('/foo/..'), '/');
is($path->cleanup('/..'), '/');
is($path->cleanup('/./..'), '/');

done_testing;


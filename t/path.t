#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;

use ok 'Gat::Path::Rules';

my $cwd = dir('.')->absolute;

my $path = Gat::Path::Rules->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    gat_dir  => $cwd->subdir('.gat'),
);

is($path->relative('foo'), 'foo');
is($path->absolute('foo'), "$cwd/src/foo");
is($path->canonical('foo'), "src/foo");
ok($path->is_valid('foo'), "is valid");
ok(!$path->is_valid('../../foo'), "is not allowed");

is($path->cleanup('/foo'), '/foo');
is($path->cleanup('/foo/..'), '/');
is($path->absolute("../foo"), "$cwd/foo");
is($path->canonical("../foo"), "foo");


ok(!$path->is_valid('/etc/passwd'),  "not valid");

done_testing;

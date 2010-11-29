#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;

use ok 'Gat::Path';

my $cwd = dir('.')->absolute;

my $path = Gat::Path->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
);

is($path->relative('foo'), 'foo');
is($path->absolute('foo'), "$cwd/src/foo");
is($path->canonical('foo'), "src/foo");
ok($path->is_valid('foo'), "is valid");
ok($path->is_allowed('foo'), "is allowed");

ok(!$path->is_valid('/etc/passwd'),  "not valid");
ok($path->is_allowed('/etc/passwd'), "allowed (but not valid)");

my $path_rules = Gat::Path->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    rules    => [ [qr/\.bak$/ => 0], [qr/~$/ => 0] ],
);

ok($path_rules->is_valid('foo.bak'), "foo.bak is valid");
ok(!$path_rules->is_allowed('foo.bak'), "foo.bak is not allowed");

# this one only allows jpg
my $path_rules2 = Gat::Path->new(
    work_dir     => $cwd->subdir('src'),
    base_dir     => $cwd,
    rules        => [ [ qr/\.jpg$/i => 1 ] ],
    rule_default => 0,
);

ok($path_rules2->is_allowed("$cwd/foo.jpg"), "allow jpg");
ok(!$path_rules2->is_allowed("$cwd/foo.gif"), "disallow gif");

done_testing;

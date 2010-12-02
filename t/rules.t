#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Gat::Path;
use Path::Class;

use ok 'Gat::Path::Rules';

my $cwd = dir('.')->absolute;

my $rules = Gat::Path::Rules->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    gat_dir  => $cwd->subdir('.gat'),
    predicates => [ [ qr/\.bak$/ => 0 ], [ qr/~$/ => 0 ] ],
);

ok(!$rules->is_allowed('foo.bak'), "foo.bak is not allowed");

# this one only allows jpg
my $rules2 = Gat::Path::Rules->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
    gat_dir  => $cwd->subdir('.gat'),
    predicates => [ [ qr/\.jpg$/i => 1],  [qr/./ => 0 ] ],
);

ok($rules2->is_allowed("$cwd/foo.jpg"), "allow jpg");
ok(!$rules2->is_allowed("$cwd/foo.gif"), "disallow gif");

done_testing;


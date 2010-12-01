#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Gat::Path;
use Path::Class;

use ok 'Gat::Rules';

my $cwd = dir('.')->absolute;

my $path = Gat::Path->new(
    work_dir => $cwd->subdir('src'),
    base_dir => $cwd,
);

my $rules = Gat::Rules->new(
    path       => $path,
    predicates => [ [ qr/\.bak$/ => 0 ], [ qr/~$/ => 0 ] ],
);

ok(!$rules->is_allowed('foo.bak'), "foo.bak is not allowed");

# this one only allows jpg
my $rules2 = Gat::Rules->new(
    path       => $path,
    predicates => [ [ qr/\.jpg$/i => 1],  [qr/./ => 0 ] ],
);

ok($rules2->is_allowed("$cwd/foo.jpg"), "allow jpg");
ok(!$rules2->is_allowed("$cwd/foo.gif"), "disallow gif");

done_testing;


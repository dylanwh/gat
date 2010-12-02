#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;

use Gat::Container;

my $cwd = dir('.')->absolute;
my $c   = Gat::Container->new( work_dir => $cwd );

$cwd->subdir('.gat')->mkpath;
$cwd->subdir('.gat')->file('rules')->openw->print(
    '^important' . "\n",
    '!\\.bak$' . "\n",
);

my $rules = $c->fetch('path_rules')->get;

ok($rules->is_allowed('pants'), "pants are allowed");
ok(!$rules->is_allowed('pants.bak'), "emergency pants are not allowed");
ok($rules->is_allowed('important-pants.bak'), "important emergency pants are allowed");

done_testing;


#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use Test::TempDir;

use ok 'Gat::Rules';

my $cwd = temp_root->absolute;

$cwd->file('rules')->openw->print(
    '/^important/' . "\n",
    '!/\\.bak$/' . "\n",
);

my $rules = Gat::Rules->new;

$rules->load_file($cwd->file('rules'));

ok($rules->is_allowed('pants'), "pants are allowed");
ok(!$rules->is_allowed('pants.bak'), "emergency pants are not allowed");
ok($rules->is_allowed('important-pants.bak'), "important emergency pants are allowed");

done_testing;

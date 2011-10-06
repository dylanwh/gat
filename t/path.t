#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Path::Class;
use Cwd;

use ok 'Gat::Path';
use ok 'Gat::Label';

my $root = temp_root()->absolute;

my $foo = Gat::Path->new( $root->file('pants') );

$foo->touch;
is($foo->digest('MD5'), 'd41d8cd98f00b204e9800998ecf8427e');
is($foo->slurp, "");
is($foo->to_label($root), 'pants');
is($foo->to_label($root)->to_path($root), $foo);

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Path::Class;
use Cwd;

use ok 'Gat::Path';

my $root = temp_root()->absolute;

my $foo = Gat::Path->new( $root->file('pants') );

$foo->touch;
is($foo->digest, 'd41d8cd98f00b204e9800998ecf8427e');


done_testing;

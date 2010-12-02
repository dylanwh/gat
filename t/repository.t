#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

my $root = temp_root->absolute;
my $asset_dir = $root->subdir('asset');
$asset_dir->mkpath;

use Gat::Repository;

my $repo = Gat::Repository->new( asset_dir => $asset_dir );

$root->file('pants.txt')->openw->print('hello, world');

my $checksum = $repo->insert( $root->file('pants.txt') );
ok(-f $root->file('pants.txt') );
unlink $root->file('pants.txt');
ok(!-f $root->file('pants.txt') );
$repo->assign( $root->file('pants.txt'), $checksum );
ok(-f $root->file('pants.txt') );

is($checksum, 'e4d7f1b4ed2e42d15898f4b27b019da4');
is($root->file(readlink($root->file('pants.txt'))), $repo->fetch($checksum));

$repo->remove($checksum);
ok(!-f $repo->resolve($checksum));

done_testing;

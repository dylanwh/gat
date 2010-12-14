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

my $checksum = $repo->insert( file => $root->file('pants.txt') );
$repo->attach(file => $root->file('pants.txt'), checksum => $checksum);
ok(-f $root->file('pants.txt') );
unlink $root->file('pants.txt');
ok(!-f $root->file('pants.txt') );
$repo->attach( file => $root->file('pants.txt'), checksum => $checksum );
ok(-f $root->file('pants.txt') );

$repo->remove(checksum => $checksum);
ok(!-f $repo->_resolve($checksum));

done_testing;

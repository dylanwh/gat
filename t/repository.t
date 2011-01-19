#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

my $root = temp_root->absolute;

use Gat;

my $gat = Gat->new(base_dir => $root, work_dir => $root);
$gat->init;

my $repo = $gat->resolve(type => 'Gat::Repository');

$root->file('pants.txt')->openw->print('hello, world');

my $checksum = $repo->store( file => $root->file('pants.txt') );
$repo->attach(file => $root->file('pants.txt'), checksum => $checksum);
ok(-f $root->file('pants.txt') );
unlink $root->file('pants.txt');
ok(!-f $root->file('pants.txt') );
$repo->attach( file => $root->file('pants.txt'), checksum => $checksum );
ok(-f $root->file('pants.txt') );

$repo->remove(checksum => $checksum);
ok(!-f $repo->_asset_file($checksum));

done_testing;

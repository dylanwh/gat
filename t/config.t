#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

use ok 'Gat::Config';
use ok 'Gat::Path';

my $root = temp_root->absolute;

my $path = Gat::Path->new(
    work_dir => $root->subdir('src'),
    base_dir => $root,
);
my $config = Gat::Config->new(path => $path);

my $file = $path->gat_file('config');
$file->parent->mkpath;
$file->openw->print("[core]\nname=test\n");

$config->load;

is($config->get( key => 'core.name'), "test");

done_testing;


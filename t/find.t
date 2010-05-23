#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

use ok 'Gat::Model';

my $root  = temp_root();
my $data  = $root->subdir('data');
$data->mkpath;
my $model = Gat::Model->new(dsn => "bdb-gin:dir=$data", extra_args => [ create => 1 ]);

isa_ok($model, 'Gat::Model');

my $foo_file = $root->file('foo');
$foo_file->openw->print("foo\n");

my $bar_file = $root->file('bar');
$bar_file->openw->print("foo\n");

my $scope = $model->new_scope;
$model->add_asset($foo_file);
$model->add_asset($bar_file);

my $files = $model->find_files('d3b07384d113edec49eaa6238ad5ff00');

diag $files->all, "\n";

done_testing;

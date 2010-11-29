#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;
use Cwd;

use ok 'Gat::Container';

my $root = temp_root->absolute;
my $cwd = cwd;

chdir $root;
mkdir ".gat";

my $c     = Gat::Container->new();
my $repo  = $c->fetch('repository')->get;
my $model = $c->fetch('model')->get;
my $path  = $c->fetch('path')->get;

my $file = "foo"; # gat add foo
$root->file($file)->openw->print("Hello\n");

if ($path->is_valid($file) and $path->is_allowed($file)) {
    my $scope    = $model->new_scope;
    my $cfile    = $path->canonical($file);
    my $afile    = $path->absolute($file);

    my $checksum = $repo->insert($afile);
    $model->add_file($cfile, $checksum);
    $repo->link($afile, $checksum);
}
is($root->file($file)->slurp, "Hello\n");

chdir $cwd;


done_testing;

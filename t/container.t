#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Container';
my $root = temp_root()->absolute;

my $c      = Gat::Container->new( base_dir => $root, work_dir => $root );
my $model  = $c->model;
my $config = $c->config;

my $repo = $c->repository;
isa_ok( $repo, 'Gat::Repository::' . $config->format );

my $repo_copy = $c->repository('FS::Copy');
isa_ok( $repo_copy, 'Gat::Repository::FS::Copy' );

my $stream = $c->resolve(
    type       => 'Gat::Path::Stream',
    parameters => { files => [] },
);


done_testing;

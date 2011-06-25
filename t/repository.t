#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;

use ok 'Gat::Container';

my $c = Gat::Container->new(base_dir => temp_root()->absolute);

my $repo = $c->resolve(type => 'Gat::Repository');
my $path = $c->resolve(type => 'Gat::Path', parameters => { filename => '/tmp/foo' });



done_testing;

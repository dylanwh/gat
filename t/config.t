#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Config';
use ok 'Gat::Repository::FS::Link';
my $root = temp_root()->absolute;

my $config = Gat::Config->new;

$config->digest_type('SHA1');
$config->store($root->file('config'));

my $config2 = Gat::Config->load($root->file('config'));
is($config2->digest_type, 'SHA1');

done_testing;

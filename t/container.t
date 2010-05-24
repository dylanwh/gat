#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

use ok 'Gat::Container';

my $root = temp_root();

my $c = Gat::Container->new(
    directory => $root,
);

my $api = $c->fetch('api')->get;

my $pants_file = $root->file('pants.txt');
$pants_file->openw->print("I like to wear pants!\n");

lives_ok {
    $api->txn_do(
        sub {
            $api->add([ $pants_file ]);
            $api->remove([ $pants_file ]);
        }
    );
};

my $pants2_file = $root->file("pants2.txt")->absolute;
$pants2_file->openw->print("I like to wear pants!\n");

lives_ok {
    $api->txn_do(
        sub {
            $api->add(    [$pants2_file] );
            #$api->remove( [$pants2_file] );
        }
    );
};

$api->save_config();

done_testing;


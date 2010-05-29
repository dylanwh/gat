#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

use ok 'Gat::Container';

my $root = temp_root();

my $c = Gat::Container->new(
    work_dir => $root,
);

my $gat = $c->gat;

my $pants_file = $root->file('pants.txt');
$pants_file->openw->print("I like to wear pants!\n");

lives_ok {
    $gat->txn_do(
        sub {
            $gat->add([ $pants_file ]);
            $gat->remove([ $pants_file ]);
        }
    );
};

my $pants2_file = $root->file("pants2.txt")->absolute;
$pants2_file->openw->print("I like to wear pants!\n");

lives_ok {
    $gat->txn_do(
        sub {
            $gat->add(    [$pants2_file] );
            #$gat->remove( [$pants2_file] );
        }
    );
};

$gat->save_config();

done_testing;


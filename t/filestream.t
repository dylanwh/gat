#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;
use Path::Class;

my $root = temp_root->absolute;
$root->file("pants")->openw->print("pants");
use Gat::Container;

my $c = Gat::Container->new(base_dir => $root, work_dir => $root);

lives_and {
    my $files = $c->resolve(type => 'Gat::FileStream', parameters => { files => [ "$root" ] });
    is_deeply([$files->all], [$root->file("pants")]);
};


done_testing;

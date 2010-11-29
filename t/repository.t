#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Repository::Local';

my $root = temp_root();

my $repo = Gat::Repository::Local->new(
    storage_dir => $root->subdir('.gat/store'),
);

isa_ok($repo, 'Gat::Repository::Local');

my $foo_file = $root->file('foo.txt');
$foo_file->openw->print("foo\n");

my $checksum = $repo->insert($foo_file);

$repo->link($foo_file, $checksum);
ok(-l $foo_file, "symlink okay");
lives_and {
    my $line = $foo_file->slurp;

    is("foo\n", $line, 'symlink works');
};

lives_and {
    $repo->unlink($foo_file, $checksum);
    ok(!-e $foo_file);
};

dies_ok {
    $repo->unlink($foo_file, $checksum);
};

$foo_file->openw->print("I like cheese");
dies_ok {
    $repo->unlink($foo_file, $checksum);
};

dies_ok {
    $repo->unlink($foo_file, '77c1d35c535e03d77dcc9ed4060db4e3');
};
ok(-e $foo_file, 'still there');

my $bar_file = $root->subdir('dir')->file('bar.txt');
$bar_file->parent->mkpath;
$bar_file->openw->print("bar\n");

my $barsum = $repo->insert($bar_file);
$repo->link($bar_file, $barsum);
ok(-l $bar_file, "symlink (bar) ok");

lives_and {
    $repo->unlink($bar_file, $barsum);
    ok(!-e $bar_file, "bar unlinked");
};

is_deeply(
    [ sort qw( c157a79031e1c40f85931829bc5fc552 d3b07384d113edec49eaa6238ad5ff00 ) ],
    [ sort $repo->assets->all ],
);

done_testing;


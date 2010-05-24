#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Store';

my $root = temp_root();

my $store = Gat::Store->new(
    storage_dir => $root->subdir('.gat/store'),
    work_dir    => $root,
    rules       => [
        [ qr/special\.jpg$/ => 0 ],
        [ qr/\.jpg$/        => 1 ],
        [ qr/\.txt$/        => 1 ],
        [ qr/passwd$/       => 1 ],
    ],
);

isa_ok($store, 'Gat::Store');

my $foo_file = $root->file('foo.txt');
$foo_file->openw->print("foo\n");

my $checksum = $store->insert($foo_file);

dies_ok {
    $root->file('pants')->openw->print('pants');
    $store->insert( $root->file('pants') );
} 'store dies';

ok(!$store->is_storable($root->subdir('.gat/store')->file('pants')), "is_storable");
ok(!$store->is_storable($root->file('pants')), "is_storable");
ok($store->is_storable($root->file('pants.jpg')), "is_storable");

$store->symlink($foo_file, $checksum);
ok(-l $foo_file, "symlink okay");
my $line = $foo_file->openr->getline;

is("foo\n", $line, 'symlink works');

$store->unlink($foo_file, $checksum);
ok(!-e $foo_file);

lives_ok {
    $store->link($foo_file, $checksum);
};
ok(-f $foo_file, "link okay");

$store->unlink($foo_file, $checksum);
ok(!-e $foo_file);

$foo_file->openw->print("I like cheese");
dies_ok {
    $store->unlink_file($foo_file, $checksum);
};

dies_ok {
    $store->unlink_file($foo_file, '77c1d35c535e03d77dcc9ed4060db4e3');
};

my $bar_file = $root->subdir('dir')->file('bar.txt');
$bar_file->parent->mkpath;
$bar_file->openw->print("bar\n");

my $barsum = $store->insert($bar_file);
$store->symlink($bar_file, $barsum);
ok(-l $bar_file, "symlink (bar) ok");

lives_ok {
    $store->unlink($bar_file, $barsum);
};
ok(!-e $bar_file, "bar unlinked");

my $passwd_file = $root->subdir('..')->file('passwd')->resolve;
$passwd_file->openw->print("foo\n");

dies_ok {
    $store->insert($passwd_file);
};

dies_ok {
    my $special_file = $root->file('special.jpg');
    $special_file->openw->print("SPECIAL!\n");
    $store->insert( $special_file );
};

done_testing;


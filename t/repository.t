#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Repository::FS::Copy';
use ok 'Gat::Repository::FS::Link';
use ok 'Gat::Repository::FS::Symlink';

my $root = temp_root()->absolute;
use CHI;

my @repos = (
    Gat::Repository::FS::Copy->new(
        asset_dir     => $root->subdir('copy')->subdir('.gat'),
        digest_type   => 'MD5',
        cache         => CHI->new( driver => 'Memory', global => 1 ),
    ),
    Gat::Repository::FS::Link->new(
        asset_dir     => $root->subdir('link')->subdir('.gat'),
        digest_type   => 'MD5',
        cache         => CHI->new( driver => 'Memory', global => 1 ),
    ),

    Gat::Repository::FS::Symlink->new(
        asset_dir     => $root->subdir('symlink')->subdir('.gat'),
        digest_type   => 'MD5',
        cache         => CHI->new( driver => 'Memory', global => 1 ),
    ),
);
use YAML::XS;

foreach my $repo (@repos) {
    $repo->init;
    my $foo = Gat::Path->new($repo->asset_dir->parent->file('foo.txt'));
    my $bar = Gat::Path->new($repo->asset_dir->parent->file('bar.txt'));

    $foo->filename->openw->print("foo\n");

    #my ($stat, $checksum) =
    my $asset = $repo->store($foo);
    my $checksum = $asset->checksum;
    ok($repo->is_attached($foo, $checksum));

    $repo->detach($foo, $checksum);
    ok(!$repo->is_attached($foo, $checksum));

    $repo->attach($bar, $checksum);
    ok($repo->is_attached($bar, $checksum));

    $repo->attach($foo, $checksum);
    ok($repo->is_attached($foo, $checksum));

    is($foo->slurp, "foo\n");
    is($bar->slurp, "foo\n");

    $repo->remove($checksum);
    ok(!$repo->is_attached($foo, $checksum), "able to remove asset from repo");
    ok(!$repo->is_attached($bar, $checksum), "able to remove asset from repo");

}

done_testing;

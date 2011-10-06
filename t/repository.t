#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Repository::FS::Copy';
use ok 'Gat::Repository::FS::Link';
use ok 'Gat::Repository::FS::Symlink';
use ok 'Gat::Repository::S3';

my $root = temp_root()->absolute;
use CHI;

my @repos = (
    Gat::Repository::FS::Link->new(
        asset_dir   => $root->subdir('link')->subdir('.gat'),
        digest_type => 'MD5',
        cache       => CHI->new( driver => 'Memory', global => 1 ),
    ),

    Gat::Repository::FS::Copy->new(
        asset_dir     => $root->subdir('copy')->subdir('.gat'),
        digest_type   => 'MD5',
        cache         => CHI->new( driver => 'Memory', global => 1 ),
    ),
 

    Gat::Repository::FS::Symlink->new(
        asset_dir     => $root->subdir('symlink')->subdir('.gat'),
        digest_type   => 'MD5',
        cache         => CHI->new( driver => 'Memory', global => 1 ),
    ),
);

if ($ENV{AWS_SECRET_ACCESS_KEY}) {
    push @repos, Gat::Repository::S3->new(
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
        bucket_name           => $ENV{S3_BUCKET_NAME},
        digest_type           => 'MD5',
        cache                 => CHI->new( driver => 'Memory', global => 1 ),
    );
}


use YAML::XS;

foreach my $repo (@repos) {
    my $dir = $repo->does('Gat::Repository::FS')
            ? $repo->asset_dir->parent
            : $root->subdir((split(/::/, ref $repo))[-1]);

    $dir->mkpath;
    $repo->init;
    my $foo = Gat::Path->new($dir->file('foo.txt'));
    my $bar = Gat::Path->new($dir->file('bar.txt'));
    my $baz = Gat::Path->new($dir->file('baz.txt'));

    $foo->filename->openw->print("foo\n");
    $baz->filename->openw->print("foo\n");

    my $asset = $repo->store($foo);
    ok($repo->is_attached($foo, $asset), 'attached after store');
    ok($repo->is_stored($asset), 'stored after store');

    $repo->store($baz);
    ok($repo->is_attached($baz, $asset), 'attached after store');

    $repo->detach($foo, $asset);
    ok(!$repo->is_attached($foo, $asset), 'detached');

    $repo->attach($bar, $asset);
    ok($repo->is_attached($bar, $asset), 'attached after attach');

    $repo->attach($foo, $asset);
    ok($repo->is_attached($foo, $asset), 'duplicate attached');

    is($foo->slurp, "foo\n", 'content check #1');
    is($bar->slurp, "foo\n", 'content check #2');
    is($baz->slurp, "foo\n", 'content check #3');

    $repo->remove($asset);
    ok(!$repo->is_stored($asset), 'removed');
    ok(!$repo->is_attached($foo, $asset), "able to remove asset from repo");
    ok(!$repo->is_attached($bar, $asset), "able to remove asset from repo");
}

done_testing;

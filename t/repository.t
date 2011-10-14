#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use CHI;
use File::MMagic;
use YAML::XS;

use ok 'Gat::Repository';
use ok 'Gat::Repository::FS::Copy';
use ok 'Gat::Repository::FS::Link';
use ok 'Gat::Repository::FS::Symlink';
use ok 'Gat::Repository::S3';
use ok 'Gat::Asset::Factory';

my $root = temp_root()->absolute;

my $factory = Gat::Asset::Factory->new(
    digest_type => 'MD5',
    file_mmagic => File::MMagic->new,
    cache       => CHI->new( driver => 'Memory', global => 1 ),
);

my @repos = (
    Gat::Repository->new(
        format => 'FS::Link',
        gat_dir   => $root->subdir('link')->subdir('.gat'),
    ),
    Gat::Repository->new(
        format => 'FS::Copy',
        gat_dir   => $root->subdir('copy')->subdir('.gat'),
    ),
    Gat::Repository->new(
        format => 'FS::Symlink',
        gat_dir   => $root->subdir('symlink')->subdir('.gat'),
    ),
);

if ( $ENV{AWS_SECRET_ACCESS_KEY} ) {
    push @repos, Gat::Repository->new(
        format => 'S3',
        format_args => {
            bucket_name           => $ENV{S3_BUCKET_NAME},
            aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
            aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
        },
        gat_dir               => $root->subdir('s3')->subdir('.gat'),
    );
}

foreach my $repo (@repos) {
    my $dir = $repo->gat_dir->parent;

    $dir->mkpath;
    $repo->init;
    my $foo = Gat::Path->new($dir->file('foo.txt'));
    my $bar = Gat::Path->new($dir->file('bar.txt'));
    my $baz = Gat::Path->new($dir->file('baz.txt'));

    $foo->filename->openw->print("foo\n");
    $baz->filename->openw->print("foo\n");

    my $asset = $factory->get_asset($foo);

    $repo->add($foo, $asset);
    ok($repo->is_attached($foo, $asset), 'attached after add');
    ok($repo->is_valid($asset), 'valid after add');

    $repo->add($baz, $factory->get_asset($baz));
    ok($repo->is_attached($baz, $asset), 'attached after add');

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
    ok(!$repo->is_valid($asset), 'removed');
    ok(!$repo->is_attached($foo, $asset), "able to remove asset from repo");
    ok(!$repo->is_attached($bar, $asset), "able to remove asset from repo");
}

done_testing;

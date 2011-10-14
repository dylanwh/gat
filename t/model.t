#!/usr/bin/env perl
use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Model';
use ok 'Gat::Schema';
use ok 'Gat::Path';
use ok 'Gat::Asset';
use ok 'Gat::Label';
use ok 'Gat::Types' => ':all';

my $root = temp_root()->absolute;

my $schema = Gat::Schema->connect('dbi:SQLite:dbname=:memory:','','');
my $model = Gat::Model->new( schema => $schema );
$model->init;

my $asset = Gat::Asset->new(
    checksum => 'f4d5239681818aa71abb02a52ccbb88d',
    mtime    => time,
    size     => 10,
    digest_type => 'MD5',
);

my $path  = Gat::Path->new($root->file('dir/foo.txt'));
my $label = $path->to_label( $root );

$model->bind($label => $asset);

is( $model->find_asset($label)->checksum, 'f4d5239681818aa71abb02a52ccbb88d' );
ok(is_Asset( $model->find_asset($label) ), "not leaking API");
does_ok($model->find_labels( $asset ), 'Data::Stream::Bulk');
does_ok($model->labels, 'Data::Stream::Bulk');
does_ok($model->assets, 'Data::Stream::Bulk');

ok(
    is_Label($model->find_labels( $asset )->next->[0]),
    'not leaking schema API',
)

;



$model->unbind($label);

done_testing;

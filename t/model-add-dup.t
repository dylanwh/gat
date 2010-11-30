#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::TempDir;

use ok 'Gat::Model';

CASE1: {
    my $model = Gat::Model->new(dsn => 'hash');
    my $scope = $model->new_scope;

    $model->add_label('foo', 'd3b07384d113edec49eaa6238ad5ff00');
    $model->add_label('bar', 'd3b07384d113edec49eaa6238ad5ff00');
    $model->add_label('foo', 'd3b07384d113edec49eaa6238ad5ff01'); # implies remove_label('foo');

    my @files = sort map { $_->[1] } $model->manifest->all;
    is_deeply(\@files, [ 'bar', 'foo' ]);

}


CASE2: {
    my $dir = temp_root->subdir('db');

    {
        my $model = Gat::Model->new(dsn => 'bdb:dir=' . $dir, extra_args => { create => 1 });
        my $scope = $model->new_scope;
        $model->add_label('OH BLARGGAG.png', 'b6e6f589895f8e57ebe71e0d72b700b3');
    }

    {
        my $model = Gat::Model->new(dsn => 'bdb:dir=' . $dir, extra_args => { create => 1 });
        my $scope = $model->new_scope;
        $model->add_label('foo/contacts.vcf', '3f2ee63eb15ea351dd860de86851f31a');
    }

    {
        my $model = Gat::Model->new(dsn => 'bdb:dir=' . $dir, extra_args => { create => 1 });
        my $scope = $model->new_scope;
        $model->add_label('foo/foo', 'd3b07384d113edec49eaa6238ad5ff00');
    }


    {
        my $model = Gat::Model->new(dsn => 'bdb:dir=' . $dir, extra_args => { create => 1 });
        my $scope = $model->new_scope;
        # mv foo/foo foo/contacts.vcf
        my $label = $model->lookup_label('foo/contacts.vcf');
        $model->add_label('foo/contacts.vcf', 'd3b07384d113edec49eaa6238ad5ff00');
        is($label->asset->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
        ok(!$model->lookup_asset("3f2ee63eb15ea351dd860de86851f31a")->has_label($label),
            "asset had label removed");
        $label = undef;
    }

    {
        my $model = Gat::Model->new(dsn => 'bdb:dir=' . $dir, extra_args => { create => 1 });
        my $scope = $model->new_scope;
        my @files = sort { $a->[1] cmp $b->[1] }  $model->manifest->all;

        my $label = $model->lookup_label('foo/contacts.vcf');
        is($label->asset->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
        ok(!$model->lookup_asset("3f2ee63eb15ea351dd860de86851f31a")->has_label($label),
            "asset had label removed (2nd block)");
        is_deeply( \@files, [ 
            ['b6e6f589895f8e57ebe71e0d72b700b3', 'OH BLARGGAG.png'],
            ['d3b07384d113edec49eaa6238ad5ff00', 'foo/contacts.vcf'],
            ['d3b07384d113edec49eaa6238ad5ff00', 'foo/foo'],
            ]
        );
    }
}

# 3f2ee63eb15ea351dd860de86851f31a  foo/contacts.vcf
# b6e6f589895f8e57ebe71e0d72b700b3  OH BLARGGAG.png
# d3b07384d113edec49eaa6238ad5ff00  foo/foo
# d3b07384d113edec49eaa6238ad5ff00  foo/contacts.vcf




done_testing;

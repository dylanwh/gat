#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Gat::Model';

use Path::Class;
my $model = Gat::Model->new(dsn => 'hash', work_dir => '.');

isa_ok($model, 'Gat::Model');

foo: {
    {
        my $scope = $model->new_scope;
        $model->add_file(file('foo'), 'd3b07384d113edec49eaa6238ad5ff00');

        my $label = $model->lookup_label(file('foo'));
        ok($label, "got foo");
        if ($label) {
            is($label->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($label->filename . "", 'foo');
        }

        $model->add_file(file('bar'), 'd3b07384d113edec49eaa6238ad5ff00');

        my $label2 = $model->lookup_label(file('bar'));
        ok($label2, "got bar");
        if ($label2) {
            is($label2->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($label2->filename . "", file('bar'));
        }

        my $asset = $model->lookup_asset('d3b07384d113edec49eaa6238ad5ff00');
        lives_ok {
            ok($asset->has_label( $model->lookup_label(file('foo')) ), "has foo");
            ok($asset->has_label( $model->lookup_label(file('bar')) ), "has bar");
        };
    }

    {
        my $scope = $model->new_scope;
        $model->add_file(file('foo'), '9ca5b5da2a7cb73eb04afc7ecfbd1912');

        my $label = $model->lookup_label(file('foo'));
        ok($label, "got foo again");
        if ($label) {
            isnt($label->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($label->filename . "", 'foo');
        
            my $asset = $model->lookup_asset('9ca5b5da2a7cb73eb04afc7ecfbd1912');
            is($label->asset, $asset);
        }
    }

    {
        my $scope = $model->new_scope;
        is($model->drop_file( file('foo') ), '9ca5b5da2a7cb73eb04afc7ecfbd1912');
        ok(!$model->lookup_label(file('foo')), 'gone');
    }
}


=pod

{
    my $scope = $model->new_scope;
    $model->add_asset('t/add.dat');

    $model->rename_asset('t/add.dat', 't/rename.dat');
    my $asset = $model->lookup('asset:t/rename.dat');
    is($asset->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
    is($asset->filename, 't/rename.dat');
}

=cut

done_testing;

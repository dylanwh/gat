#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Gat::Model';

my $model = Gat::Model->new(dsn => 'hash');

isa_ok($model, 'Gat::Model');

foo: {
    {
        my $scope = $model->new_scope;
        $model->add_file('foo', 'd3b07384d113edec49eaa6238ad5ff00');

        my $name = $model->lookup_name('foo');
        ok($name, "got foo");
        if ($name) {
            is($name->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($name->filename . "", 'foo');
        }

        $model->add_file('bar', 'd3b07384d113edec49eaa6238ad5ff00');

        my $name2 = $model->lookup_name('bar');
        ok($name2, "got bar");
        if ($name2) {
            is($name2->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($name2->filename . "", 'bar');
        }

        my $asset = $model->lookup_asset('d3b07384d113edec49eaa6238ad5ff00');
        lives_ok {
            ok($asset->has_name( $model->lookup_name('foo') ), "has foo");
            ok($asset->has_name( $model->lookup_name('bar') ), "has bar");
        };
    }

    {
        my $scope = $model->new_scope;
        $model->add_file('foo', '9ca5b5da2a7cb73eb04afc7ecfbd1912');

        my $name = $model->lookup_name('foo');
        ok($name, "got foo again");
        if ($name) {
            isnt($name->checksum, 'd3b07384d113edec49eaa6238ad5ff00');
            is($name->filename . "", 'foo');
        
            my $asset = $model->lookup_asset('9ca5b5da2a7cb73eb04afc7ecfbd1912');
            is($name->asset, $asset);
        }
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

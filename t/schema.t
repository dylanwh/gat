#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use ok 'Gat::Schema';

my $schema = Gat::Schema->connect('dbi:SQLite:dbname=:memory:','','');
$schema->deploy;

my $asset = $schema->resultset('Asset')->create(
    {   
        checksum => 'foo',
        mtime    => time,
        size     => 10,
        digest_type => 'MD5',
        content_type => 'text/plain',
    }
);

$schema->resultset('Label')->create(
    { asset => $asset, filename => "foo/bar" }
);

my $label = $schema->resultset('Label')->find({filename => "foo/bar"});
is($label->asset->checksum, "foo");

is($schema->resultset('Asset')->find({checksum => 'foo'})->labels->first->filename, $label->filename);

done_testing;

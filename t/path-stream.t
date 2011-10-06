
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;
use Test::Exception;

use ok 'Gat::Path::Stream';
use ok 'Gat::Path::Sieve';

my $root = temp_root()->absolute;

my $sieve = Gat::Path::Sieve->new(
    rules     => [ [ qr/\.bak/ => 0 ], ],
    base_dir  => $root,
    gat_dir   => $root->subdir('.gat'),
    asset_dir => $root->subdir('.gat/asset'),
);

$root->subdir('.gat/asset')->mkpath;
$root->file('.gat/asset/foo')->touch;
$root->file('foo')->touch;
$root->subdir('dir')->mkpath;
$root->subdir('dir')->file('soap.bak')->touch;
$root->file('foo.bak')->touch;

my $stream = Gat::Path::Stream->new(
    files => [$root],
    sieve => $sieve,
    work_dir => $root,
);

is_deeply( [map { "$_" } $stream->all], [Gat::Path->new( $root->file('foo') )]);

my $stream2 = Gat::Path::Stream->new(
    files => [$root->subdir('dir')],
    sieve => $sieve,
    work_dir => $root,
);

is_deeply( [$stream2->all], []);

ok($sieve->match(Gat::Path->new($root->file('foo'))));
ok(!$sieve->match(Gat::Path->new($root->file('foo.bak'))));

dies_ok {
    my $stream3 = Gat::Path::Stream->new(
        files => [$root->file('foo.bak')],
        sieve => $sieve,
        work_dir => $root,
    );
    $stream3->all;
} 'dies when adding forbidden file';




done_testing;

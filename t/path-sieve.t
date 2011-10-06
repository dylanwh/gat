#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Gat::Path::Sieve';
use ok 'Gat::Path';

my $sieve = Gat::Path::Sieve->new(
    rules => [
        [qr/\.bak/ => 0],
    ],
    base_dir => '/tmp',
    gat_dir  => '/tmp/.gat',
    asset_dir  => '/tmp/asset',
);

my $footxt = Gat::Path->new(filename => '/tmp/foo.txt');
my $foobak = Gat::Path->new(filename => '/tmp/foo.bak');
my $foobak2 = Gat::Path->new(filename => '/tmp/foo.txt~');
my $passwd = Gat::Path->new(filename => '/etc/passwd');
my $config = Gat::Path->new(filename => '/tmp/.gat/config');
my $asset  = Gat::Path->new(filename => '/tmp/asset');

$sieve->add_rule([qr/~$/ => 0]);

ok($sieve->match($footxt));
ok(!$sieve->match($foobak));
ok(!$sieve->match($foobak2));
ok(!$sieve->match($passwd));
ok(!$sieve->match($config));
ok(!$sieve->match($asset));

$sieve->parse_rule('!*');

ok(!$sieve->match($footxt));

done_testing;

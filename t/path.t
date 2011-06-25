#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use Cwd;

use ok 'Gat::Container';

my $c = Gat::Container->new(base_dir => '/tmp');

my $path = $c->resolve(type => 'Gat::Path', parameters => { filename => '/tmp/foo' });

$path->touch;
is($path->checksum, "d41d8cd98f00b204e9800998ecf8427e");

my $sieve = $c->resolve(type => 'Gat::Path::Sieve', parameters => { rules => [[qr/./, 1]] });
my $stream = $c->resolve(type => 'Gat::Path::Stream', parameters => { paths => [] } );

done_testing;

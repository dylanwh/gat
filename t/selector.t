#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Gat::Selector;
my $sel = Gat::Selector->new(
    rules => [ 
        [ qr/pants\.jpg/ => 0 ],
        [ qr/\.jpe?g$/   => 1 ],
        [ qr/\.p[lm]c?$/ => 0 ],
    ],
    rule_default => 1,
);

ok($sel->match('foo.jpg'), 'foo.jpg');
ok(!$sel->match('foo.pl'), 'foo.pl');
ok(!$sel->match('pants.jpg'), 'pants.jpg');
ok($sel->match('anything.else'), 'anything.else');

ok(!$sel->match('/etc/passwd'), '/etc/passwd');
ok(!$sel->match('.gat/config'), '.gat/config');


done_testing;


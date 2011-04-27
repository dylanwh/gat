#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Path::Class;
use Cwd;

use ok 'Gat::Path';
use ok 'Gat::Label';
use ok 'Gat::Context';
use ok 'Gat::Rules';

my $ctx = Gat::Context->new(
    work_dir => cwd . '/fake/workdir',
    base_dir => cwd . '/fake',
);
ok($ctx, "got context");

my $lfoo = $ctx->label(cwd . '/fake/workdir/foo');
my $pfoo = $ctx->path('foo');

diag $lfoo->filename;
diag $pfoo->filename;

is($pfoo->to_label($ctx)->filename, $lfoo->filename);
is($lfoo->to_path($ctx)->filename, $pfoo->filename);

done_testing;

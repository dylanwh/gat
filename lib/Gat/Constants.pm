package Gat::Constants;
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports    => [qw[ WIN32 GAT_DIR GAT_HASH ]],
    collectors => [qw[ all ]],
};

use constant {
    WIN32    => $^O eq 'Win32',
    GAT_DIR  => $ENV{GAT_DIR}  || '.gat',
    GAT_HASH => $ENV{GAT_HASH} || 'MD5',
};

1;

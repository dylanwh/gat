package Gat::Constants;
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports    => [qw[ WIN32 GAT_DIR GAT_REALPATH ]],
    collectors => [qw[ all ]],
};

use constant {
    WIN32        => $^O eq 'Win32',
    GAT_DIR      => $ENV{GAT_DIR}     // '.gat',
    GAT_REALPATH => $ENV{GAT_REALPATH} // 1,
};

1;

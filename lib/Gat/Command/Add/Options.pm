package Gat::Command::Add::Options;
use Moose;
use namespace::autoclean;

with 'MooseX::Getopt::Dashes';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'verbose' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;
1;


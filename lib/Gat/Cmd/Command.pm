package Gat::Cmd::Command;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'Dir';

extends qw(MooseX::App::Cmd::Command);
with 'MooseX::Getopt::Dashes';

has 'verbose' => (
    traits      => ['Getopt'],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    cmd_aliases => 'v',
);

has 'work_dir' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => Dir,
    default     => '.',
    coerce      => 1,
    cmd_aliases => 'C',
);

__PACKAGE__->meta->make_immutable;

1;

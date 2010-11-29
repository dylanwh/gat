package Gat::Cmd::Command;
use Moose;
use namespace::autoclean;

use Gat::Cmd::Container;

extends qw(MooseX::App::Cmd::Command);
with 'MooseX::Getopt::Dashes';

has 'container' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'Gat::Cmd::Container',
    default => sub { Gat::Cmd::Container->new },
    handles => [qw[fetch]],
);

__PACKAGE__->meta->make_immutable;

1;

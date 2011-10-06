package Gat::Cmd;
use Gat::Moose;
use namespace::autoclean;

use Gat;
extends qw(MooseX::App::Cmd);


__PACKAGE__->meta->make_immutable;
1;


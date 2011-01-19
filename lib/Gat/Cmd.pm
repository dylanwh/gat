package Gat::Cmd;
use Moose;
use namespace::autoclean;

use Gat;
extends qw(MooseX::App::Cmd);


__PACKAGE__->meta->make_immutable;
1;


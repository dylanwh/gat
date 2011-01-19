package Gat::Cmd::Command::Init;
use Moose;
use namespace::autoclean;

use Gat::Container;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt, $files ) = @_;
   
    Gat->new ( work_dir => $self->work_dir->absolute, base_dir => $self->work_dir->absolute )
       ->init( verbose => $self->verbose );
}

__PACKAGE__->meta->make_immutable;
1;

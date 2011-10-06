package Gat::Cmd::Command::Init;
use Gat::Moose;
use namespace::autoclean;

use Gat::Container;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt ) = @_;

    my $c = $self->container;
    $c->resolve(service => 'gat_dir')->mkpath;
    $c->model->init;
    $c->repository->init;
    $c->config->init( $c->resolve(service => 'config_file') );
}

__PACKAGE__->meta->make_immutable;
1;

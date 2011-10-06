package Gat::Cmd::Command::Init;
use Gat::Moose;
use namespace::autoclean;

use Gat::Container;

extends 'Gat::Cmd::Command';

has 'format' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_format',
);

has 'digest_type' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_digest_type',
);

sub execute {
    my ( $self, $opt ) = @_;

    my $c = $self->container;
    $c->resolve(service => 'gat_dir')->mkpath;

    my $config = $c->config;
    $config->format( $self->format )           if $self->has_format;
    $config->digest_type( $self->digest_type ) if $self->has_digest_type;
    $config->store( $c->resolve( service => 'config_file' ) );

    $c->model->init;
    $c->repository->init;
}

__PACKAGE__->meta->make_immutable;
1;

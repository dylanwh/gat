package Gat::Cmd::Command::Init;
use Gat::Moose;
use namespace::autoclean;

use Gat::Container;

extends 'Gat::Cmd::Command';

has 'format' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => 'Str',
    cmd_aliases => 'F',
    default     => 'FS::Link',
);

has 'format_option' => (
    traits    => ['Getopt'],
    is        => 'ro',
    isa       => 'HashRef[Str]',
    cmd_aliases => 'o',
    default => sub { +{} },
);

has 'digest_type' => (
    is        => 'ro',
    isa       => 'Str',
    default   => 'MD5',
);

sub execute {
    my ( $self, $opt ) = @_;

    my $gat = $self->gat;
    $gat->gat_dir->mkpath;

    my $config = $gat->config;
    $config->set(
        key   => 'asset_factory.digest_type',
        value => $self->digest_type,
    );

    $config->set_hash(
        key   => 'repository',
        value => {
            format => $self->format,
            %{ $self->format_option },
        },
    );

    $gat->model->init;
    $gat->repository->init;
}

__PACKAGE__->meta->make_immutable;
1;

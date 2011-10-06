# ABSTRACT: A Glorious Asset Tracker

package Gat;
use Gat::Moose;
use namespace::autoclean;

use Gat::Types ':all';

has 'repository' => (
    is       => 'ro',
    does     => 'Gat::Repository',
    required => 1,
);

has 'model' => (
    is       => 'ro',
    isa      => 'Gat::Model',
    required => 1,
);

has 'gat_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

sub init {
    my $self = shift;

    $self->gat_dir->mkpath;
    $self->model->init;
    $self->repository->init;
}

__PACKAGE__->meta->make_immutable;

1;

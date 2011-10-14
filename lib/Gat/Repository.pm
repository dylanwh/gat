package Gat::Repository;
use Moose;
use namespace::autoclean;

use Gat::Repository::API;

has 'format' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'format_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has 'repository' => (
    is      => 'ro',
    does    => 'Gat::Repository::API',
    builder => '_build_repository',
    lazy    => 1,
    handles => 'Gat::Repository::API',
);

sub _build_repository {
    my $self = shift;
    my $class = 'Gat::Repository::' . $self->format;
    my $args  = $self->format_args;
    Class::MOP::load_class($class);

    return $class->new( %$args, gat_dir => $self->gat_dir, );
}

with 'Gat::Repository::API';

__PACKAGE__->meta->make_immutable;

1;

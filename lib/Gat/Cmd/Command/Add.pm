package Gat::Cmd::Command::Add;
use Gat::Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self, $opt, $files ) = @_;

    my $c      = $self->container;
    my $stream = $c->path_stream($files);
    my $repo   = $c->repository;
    my $model  = $c->model;
    
    until ( $stream->is_done ) {
        foreach my $path ( $stream->items ) {
            my $asset = $repo->store($path);
            $model->bind(
                $path->to_label( $c->base_dir ) => $asset
            );
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;


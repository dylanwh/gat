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

    my $gat    = $self->gat;
    my $stream = $gat->path_stream($files);
    my $repo   = $gat->repository;
    my $model  = $gat->model;
    my $factory = $gat->asset_factory;
    
    until ( $stream->is_done ) {
        foreach my $path ( $stream->items ) {
            my $asset = $factory->get_asset($path);
            $repo->add($path, $asset);
            $model->bind(
                $path->to_label( $gat->base_dir ) => $asset
            );
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;


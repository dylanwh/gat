package Gat::Cmd::Command::restore;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $model = $self->fetch('model')->get;
    my $repo  = $self->fetch('repository')->get;
    my $path  = $self->fetch('path')->get;

    for my $file (@$files) {
        die "invalid path: $file"    unless $path->is_valid($file);
        die "disallowed path: $file" unless $path->is_allowed($file) or $self->force;

        my $scope    = $model->new_scope;
        my $cfile    = $path->canonical($file);
        my $afile    = $path->absolute($file);

        my $label = $model->lookup_label($cfile);
        if ($label) {
            $repo->link($afile, $label->checksum);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;


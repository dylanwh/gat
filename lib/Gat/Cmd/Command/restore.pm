package Gat::Cmd::Command::restore;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $c = Gat::Container->new(work_dir => $self->work_dir->absolute);

    $c->check_workspace;
    my $path  = $c->fetch('Path')->get;
    my $model = $c->fetch('Model/instance')->get;
    my $repo  = $c->fetch('Repository/instance')->get;

    for my $file (@$files) {
        die "invalid path: $file"    unless $path->is_valid($file);
        die "disallowed path: $file" unless $path->is_allowed($file) or $self->force;

        my $scope    = $model->new_scope;
        my $cfile    = $path->canonical($file);
        my $afile    = $path->absolute($file);

        my $label = $model->lookup_label($cfile);
        $repo->attach($afile, $label->checksum) if $label;
    }
}

__PACKAGE__->meta->make_immutable;
1;


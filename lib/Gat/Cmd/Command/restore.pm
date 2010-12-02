package Gat::Cmd::Command::restore;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $c = Gat::Container->new(work_dir => $self->work_dir->absolute);

    $c->check_workspace;
    my $model = $c->fetch('model')->get;
    my $repo  = $c->fetch('repository')->get;
    my $rules = $c->fetch('path_rules')->get;

    for my $file (@$files) {
        die "invalid path: $file"    unless $rules->is_valid($file);
        die "disallowed path: $file" unless $rules->is_allowed($file) or $self->force;

        my $scope    = $model->new_scope;
        my $cfile    = $rules->canonical($file);
        my $afile    = $rules->absolute($file);

        my $label = $model->lookup_label($cfile);
        if ($label) {
            $repo->assign($afile, $label->checksum);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;


package Gat::Cmd::Command::rm;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    $c->check_workspace;

    my $model = $c->fetch('Model/instance')->get;
    my $repo  = $c->fetch('Repository/instance')->get;
    my $path  = $c->fetch('Path')->get;
    my $scope = $model->new_scope;

    for my $file (@$files) {
        die "invalid path: $file\n"    unless $path->is_valid($file);
        die "disallowed path: $file\n" unless $path->is_allowed($file) or $self->force;

        my $cfile    = $path->canonical($file);
        my $afile    = $path->absolute($file);
        my $checksum = $model->remove_label($cfile);
        $repo->detach( file => $afile, checksum => $checksum ) if -e $afile;
        $repo->remove( checksum => $checksum );
    }
}

__PACKAGE__->meta->make_immutable;
1;


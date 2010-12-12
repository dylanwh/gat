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
    my $path  = $c->fetch('Path')->get;
    my $scope = $model->new_scope;

    for my $file (@$files) {
        die "invalid path: $file\n"    unless $path->is_valid($file);
        die "disallowed path: $file\n" unless $path->is_allowed($file) or $self->force;
        die "still exists: $file\n"    if -f $file;

        my $cfile = $path->canonical($file);

        $model->remove_label($cfile);
    }
}

__PACKAGE__->meta->make_immutable;
1;


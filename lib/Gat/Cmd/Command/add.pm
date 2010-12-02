package Gat::Cmd::Command::add;
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

    my $model = $c->fetch('model')->get;
    my $repo  = $c->fetch('repository')->get;
    my $rules = $c->fetch('path_rules')->get;
    my $scope = $model->new_scope;

    for my $file (@$files) {
        die "invalid path: $file"    unless $rules->is_valid($file);
        die "disallowed path: $file" unless $rules->is_allowed($file) or $self->force;

        my $cfile    = $rules->canonical($file);
        my $afile    = $rules->absolute($file);

        my ($checksum, $stat) = $repo->insert($afile);
        $model->add_label($cfile, $checksum, $size);
    }
}

__PACKAGE__->meta->make_immutable;
1;


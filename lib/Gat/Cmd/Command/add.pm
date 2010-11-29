package Gat::Cmd::Command::add;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'verbose' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $model = $self->fetch('model')->get;
    my $repo  = $self->fetch('repository')->get;
    my $path  = $self->fetch('path')->get;

    for my $file (@$files) {
        next if not -f $file;
        die "invalid path: $file"    unless $path->is_valid($file);
        die "disallowed path: $file" unless $path->is_allowed($file) or $self->force;

        my $scope    = $model->new_scope;
        my $cfile    = $path->canonical($file);
        my $afile    = $path->absolute($file);

        my $checksum = $repo->insert($afile);
        $model->add_file($cfile, $checksum);
        $repo->link($afile, $checksum);
    }
}

__PACKAGE__->meta->make_immutable;
1;


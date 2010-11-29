package Gat::Command::Add;
use Moose;
use namespace::autoclean;

has 'options' => (
    is       => 'ro',
    isa      => 'Gat::Command::Add::Options',
    required => 1,
    handles  => [qw[ force verbose ]],
);

has 'model'      => ( is => 'ro', isa  => 'Gat::Model',           required => 1, );
has 'repository' => ( is => 'ro', does => 'Gat::Repository::API', required => 1 );
has 'path'       => ( is => 'ro', isa  => 'Gat::Path',            required => 1 );

sub run {
    my ( $self, @files ) = @_;
    my $model = $self->model;
    my $repo  = $self->repository;
    my $path  = $self->path;

    for my $file (@files) {
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

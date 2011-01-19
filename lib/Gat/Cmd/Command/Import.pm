package Gat::Cmd::Command::Import;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File';

extends 'Gat::Cmd::Command';

has 'file' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => File,
    coerce      => 1,
    cmd_aliases => 'f',
    predicate => 'has_file',
);

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $gat = Gat->new(
        work_dir => $self->work_dir->absolute,
    );
    $gat->check_workspace;
    $gat->import_model( $self->has_file ? (file => $self->file) : () );
}

__PACKAGE__->meta->make_immutable;
1;


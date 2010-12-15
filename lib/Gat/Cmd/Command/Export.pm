package Gat::Cmd::Command::Export;
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
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    my $gat = $c->fetch('App')->get;
    $gat->check_workspace;

    $gat->export_model( $self->has_file ? (file => $self->file) : () );
}

__PACKAGE__->meta->make_immutable;
1;


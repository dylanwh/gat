package Gat::Cmd::Command::Files;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

has 'null' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self ) = @_;
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    my $gat = $c->fetch('App')->get;
    $gat->check_workspace;

    $gat->print_files(null => $self->null);
}

__PACKAGE__->meta->make_immutable;
1;


package Gat::Cmd::Command::Unhide;
use Moose;
use namespace::autoclean;
use Gat::FileStream;

extends 'Gat::Cmd::Command';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self ) = @_;
    my $gat = Gat->new(
        work_dir => $self->work_dir->absolute,
    );

    $gat->check_workspace;
    $gat->unhide( verbose => $self->verbose, force => $self->force );
}

__PACKAGE__->meta->make_immutable;
1;


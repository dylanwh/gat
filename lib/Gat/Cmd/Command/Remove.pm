package Gat::Cmd::Command::Remove;
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
    my $gat = Gat->new(
        work_dir => $self->work_dir->absolute,
    );

    $gat->check_workspace;

    my $stream = $gat->resolve(
        type       => 'Gat::FileStream',
        parameters => { files => $files },
    );

    $gat->remove( files => $stream, verbose => $self->verbose, force => $self->force );
}

__PACKAGE__->meta->make_immutable;
1;


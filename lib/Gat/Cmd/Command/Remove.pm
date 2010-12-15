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
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    my $gat = $c->fetch('App')->get;
    $gat->check_workspace;

    my $stream = Gat::FileStream->new(files => $files);
    $gat->remove( files => $stream, verbose => $self->verbose, force => $self->force );
}

__PACKAGE__->meta->make_immutable;
1;


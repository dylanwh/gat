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
    my $gat = Gat->new(
        work_dir => $self->work_dir->absolute,
    );
    $gat->check_workspace;
    $gat->print_files(null => $self->null, filter => sub { -f $_ });
}

__PACKAGE__->meta->make_immutable;
1;


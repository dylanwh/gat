package Gat::Cmd::Command::Hide;
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
    my ( $self, $opt, $files ) = @_;
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    my $gat   = $c->fetch('App')->get;
    my $path  = $c->fetch('Path')->get;
    my $model = $c->fetch('Model')->get;
    my $scope = $model->new_scope;
    $gat->check_workspace;

    my $stream = Data::Stream::Bulk::Filter->new(
        filter => sub {
            [ map { $path->base_dir->file($_) } @$_ ]
        },
        stream => $model->files,
    );
    $gat->hide( files => $stream, verbose => $self->verbose, force => $self->force );
}

__PACKAGE__->meta->make_immutable;
1;


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
    my $gat = Gat->new(
        work_dir => $self->work_dir->absolute,
    );

    my $path  = $gat->resolve(type => 'Gat::Path');
    my $model = $gat->resolve(type => 'Gat::Model');
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


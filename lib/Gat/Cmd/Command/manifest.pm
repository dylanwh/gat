package Gat::Cmd::Command::manifest;
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

sub execute {
    my ($self) = @_;
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    $c->check_workspace;

    my $model = $c->fetch('model')->get;
    my $scope = $model->new_scope;
    my $s     = $model->manifest;

    until ( $s->is_done ) {
        foreach my $item ( $s->items ) {
            print "$item->[0]  $item->[1]\n";
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;



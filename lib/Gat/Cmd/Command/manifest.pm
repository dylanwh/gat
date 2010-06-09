package Gat::Cmd::Command::manifest;
use feature 'say';
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

use Gat;
use Path::Class;

sub invoke {
    my ($self, $gat, @args) = @_;
    my $model  = $gat->model;
    my $stream = $model->manifest;

    until ( $stream->is_done ) {
        for my $item ( $stream->items ) {
            printf "%s  %s\n", @$item;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

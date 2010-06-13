package Gat::Cmd::Command::manifest;

# ABSTRACT: Print or save the gat manifest

use feature 'say';
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

use Gat;
use Path::Class;
use MooseX::Types::Moose ':all';

has 'print' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => Bool,
    lazy_build  => 1,
    cmd_aliases => 'p',
);

has 'save' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => Bool,
    default     => 0,
    cmd_aliases => 's',
);

sub _build_print {
    my ($self) = @_;
    return not $self->save 
}

=head1 SYNOPSIS

    gat manifest

=cut

sub invoke {
    my ($self, $gat, @args) = @_;
    my $model  = $gat->model;
    my $stream = $model->manifest;

    my $save_fh;

    until ( $stream->is_done ) {
        for my $item ( $stream->items ) {
            printf "%s  %s\n", @$item if $self->print;
            if ($save_fh) {
                printf $save_fh "%s  %s\n", @$item;
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

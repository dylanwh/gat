package Gat::Cmd::Command::restore;

# ABSTRACT: restore a file from the gat store

use feature 'say';
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

use Path::Class;
use MooseX::Types::Path::Class 'File';
use Data::Stream::Bulk::Path::Class;

=head1 SYNOPSIS

    gat restore file [file2 [dir...]]

=cut

sub invoke {
    my ($self, $gat, @args) = @_;

    my $file = file(shift @args);
    $gat->restore($file);
    say "Restored $file";
}

__PACKAGE__->meta->make_immutable;

1;

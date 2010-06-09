package Gat::Cmd::Command::add;

# ABSTRACT: insert a file into the gat store.

use feature 'say';
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

use Path::Class;
use MooseX::Types::Path::Class 'File';
use Data::Stream::Bulk::Path::Class;

=head1 SYNOPSIS

    gat add file [file2 [dir...]]

=cut

sub invoke {
    my ($self, $gat, @args) = @_;
    my $file = file(shift @args);
    say $gat->add($file) ? "added $file" : "failed to add $file";
}

__PACKAGE__->meta->make_immutable;

1;

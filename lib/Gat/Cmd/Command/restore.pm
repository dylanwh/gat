package Gat::Cmd::Command::restore;
use feature 'say';
use Moose;
use namespace::autoclean;

extends 'Gat::Cmd::Command';

use Path::Class;
use MooseX::Types::Path::Class 'File';
use Data::Stream::Bulk::Path::Class;

sub invoke {
    my ($self, $gat, @args) = @_;

    my $file = file(shift @args);
    $gat->restore($file);
    say "Restored $file";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Gat::Cmd::Command::restore - restore a file from the gat store

=head1 SYNOPSIS

    gat restore file [file2 [dir...]]



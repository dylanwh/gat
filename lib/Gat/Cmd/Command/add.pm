package Gat::Cmd::Command::add;
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
    say $gat->add($file) ? "added $file" : "failed to add $file";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Gat::Cmd::Command::add - insert a file into the gat store.

=head1 SYNOPSIS

    gat add file [file2 [dir...]]



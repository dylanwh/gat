package Gat::Schema::Asset;
use Moose;
use namespace::autoclean;

with 'KiokuDB::Role::ID';

use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose ':all';
use KiokuDB::Util qw( weak_set set );

use Gat::Types 'Label', 'Checksum';

has '_labels' => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { set() },
    handles  => {
        add_label    => 'insert',
        remove_label => 'remove',
        has_label    => 'contains',
    },
);

has 'checksum' => (
    is       => 'rw',
    isa      => Checksum,
    required => 1,
);

sub files {
    my ($self) = @_;
    my @files = map { $_->filename } $self->_labels->members;
    return wantarray ? @files : \@files;
}

sub kiokudb_object_id {
    my ($self) = @_;
    return 'asset:' . $self->checksum;
}

__PACKAGE__->meta->make_immutable;

1;

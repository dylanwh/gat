package Gat::Schema::Label;
use Moose;
use namespace::autoclean;

with 'KiokuDB::Role::ID';

use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose ':all';
use Gat::Types 'Asset';

has 'filename' => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

has 'asset' => (
    is       => 'rw',
    isa      => Maybe[Asset],
    required => 1,
    weak_ref => 1,
    handles => ['checksum'],
);

sub kiokudb_object_id {
    my ($self) = @_;

    return 'label:' . $self->filename;
}

__PACKAGE__->meta->make_immutable;

1;


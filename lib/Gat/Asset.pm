package Gat::Asset;
use Moose;
use namespace::autoclean;

with 'KiokuDB::Role::ID';

use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use KiokuDB::Util qw( weak_set set );

use Gat::Types 'Label', 'Checksum';

has '_labels' => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { set() },
    handles  => {
        has_label    => 'contains',
    },
);

has 'size' => (
    is       => 'rw',
    isa      => Int,
    required => 1,
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

sub add_label {
    my $self = shift;
    my ($label) = pos_validated_list(\@_, { isa => Label });

    $label->asset( $self );
    $self->_labels->insert($label);
}

sub remove_label {
    my $self = shift;
    my ($label) = pos_validated_list(\@_, { isa => Label });

    $label->asset(undef);
    $self->_labels->remove($label);
}

__PACKAGE__->meta->make_immutable;

1;

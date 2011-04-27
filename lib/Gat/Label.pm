package Gat::Label;
use Moose;
use namespace::autoclean;

with 'KiokuDB::Role::ID';

use MooseX::Params::Validate;
use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose ':all';
use Gat::Types 'Asset', 'RelativeFile';

with 'Gat::Role::HasFilename' => { filename_isa => RelativeFile };

has 'asset' => (
    is       => 'rw',
    isa      => Maybe[Asset],
    default  => sub { undef },
    weak_ref => 1,
    handles => ['checksum'],
);

sub to_path {
    my $self = shift;
    my ($ctx) = pos_validated_list( \@_, { isa => 'Gat::Context' } );

    return Gat::Path->new($self->filename->absolute( $ctx->base_dir ));
}

sub is_allowed {
    my $self = shift;
    my ($ctx) = pos_validated_list( \@_, { isa => 'Gat::Context' } );

    return $ctx->is_allowed( $self->filename );
}

sub kiokudb_object_id {
    my ($self) = @_;

    return 'label:' . $self->filename;
}

__PACKAGE__->meta->make_immutable;

1;

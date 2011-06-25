package Gat::Label;
use Moose;
use namespace::autoclean;

with 'KiokuDB::Role::ID';

use MooseX::Params::Validate;
use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose ':all';
use MooseX::StrictConstructor;

use Gat::Types 'Asset', 'RelativeFile', 'AbsoluteDir';

has 'name' => (
    is       => 'ro',
    isa      => RelativeFile,
    required => 1,
    initializer => '_init_name',
);

has 'asset' => (
    is       => 'rw',
    isa      => Maybe[Asset],
    default  => sub { undef },
    weak_ref => 1,
    handles => ['checksum'],
);

has 'filename' => (
    traits     => ['KiokuDB::DoNotSerialize'],
    is         => 'ro',
    isa        => File,
    init_arg   => undef,
    lazy_build => 1,
);

sub to_path {
    my $self = shift;
    my ($ctx) = pos_validated_list(\@_, { isa => PathContext });

    return Gat::Path->new( filename => $self->name->absolute( $ctx->work_dir ), context => $ctx );
}

sub has_asset {
    my $self = shift;
    defined $self->asset;
}

sub _init_name {
    my ( $self, $name, $set, $attr ) = @_;
    $set->($name->as_foreign('Unix'));
}

sub _build_filename {
    my ($self) = @_;

    Path::Class::File->new(
        File::Spec::Unix->splitdir($self->name)
    );
}

sub kiokudb_object_id {
    my ($self) = @_;

    return 'label:' . $self->filename;
}

__PACKAGE__->meta->make_immutable;

1;

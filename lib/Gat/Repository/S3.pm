package Gat::Repository::S3;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Net::Amazon::S3;
use Net::Amazon::S3::Client;

use Gat::Types ':all';
use Gat::Path;

with 'Gat::Repository::API';

has [ 'bucket_name', 'aws_access_key_id', 'aws_secret_access_key' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 's3_client' => (
    is       => 'ro',
    isa      => 'Net::Amazon::S3::Client',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_s3_client',
);

has 's3_bucket' => (
    is       => 'ro',
    isa      => 'Net::Amazon::S3::Client::Bucket',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_s3_bucket',
);

sub _build_s3_client {
    my $self = shift;

    return Net::Amazon::S3::Client->new(
        s3 => Net::Amazon::S3->new(
            retry                 => 1,
            aws_access_key_id     => $self->aws_access_key_id,
            aws_secret_access_key => $self->aws_secret_access_key,
        ),
    );

}

sub _build_s3_bucket {
    my $self = shift;

    return $self->s3_client->bucket( name => $self->bucket_name );
}

sub init {
    my $self = shift;

    $self->s3_client->create_bucket(
        name                => $self->bucket_name,
        acl_short           => 'private',
        location_constraint => 'US',
    );
}

sub add {
    my $self = shift;
    my ($path, $asset) = pos_validated_list( \@_, { isa => Path }, { isa => AssetMD5 } );
    my $object = $self->_asset_object($asset);

    $object->put_filename( $path->filename );
}

sub remove {
    my $self = shift;
    my ($asset) = pos_validated_list( \@_, { isa => AssetMD5 } );
    my $object = $self->_asset_object($asset);
    $object->delete;
}

sub is_valid {
    my $self = shift;
    my ($asset) = pos_validated_list( \@_, { isa => AssetMD5 } );
    my $object = $self->_asset_object($asset);
    return $object->exists;
}

sub attach {
    my $self = shift;
    my ($path, $asset) = pos_validated_list( \@_, { isa => Path}, { isa => AssetMD5 } );

    return if $self->is_attached($path, $asset);

    my $object = $self->_asset_object($asset);
    $object->get_filename($path->filename->stringify) if $object->exists;
}

sub is_attached {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => AssetMD5 } );
    my $stat = $path->stat;

    return $stat
        && $stat->size == $asset->size
        && $self->is_valid($asset)
        && $path->digest( $asset->digest_type ) eq $asset->checksum;
}

sub clone { }

sub _asset_object {
    my ($self, $asset) = @_;

    return $self->s3_bucket->object(
        key          => $asset->checksum,
        size         => $asset->size,
        etag         => $asset->checksum,
        content_type => $asset->content_type,
    );
}

__PACKAGE__->meta->make_immutable;

1;

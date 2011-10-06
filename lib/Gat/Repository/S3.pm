package Gat::Repository::S3;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;
use Net::Amazon::S3;
use Net::Amazon::S3::Client;

use Gat::Types ':all';
use Gat::Path;

with 'Gat::Repository';

has 'aws_access_key_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'aws_secret_access_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'bucket_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 's3_client' => (
    is      => 'ro',
    isa     => 'Net::Amazon::S3::Client',
    builder => '_build_s3_client',
    lazy    => 1,
);

has 's3_bucket' => (
    is      => 'ro',
    isa     => 'Net::Amazon::S3::Client::Bucket',
    builder => '_build_s3_bucket',
    lazy    => 1,
);

sub BUILD {
    my $self = shift;

    die "S3 can only use the digest_type MD5!" unless $self->digest_type eq 'MD5';
}

sub _build_s3_client {
    my $self = shift;

    my $s3 = Net::Amazon::S3->new(
        aws_access_key_id     => $self->aws_access_key_id,
        aws_secret_access_key => $self->aws_secret_access_key,
        retry                 => 1,
    );

    return Net::Amazon::S3::Client->new( s3 => $s3 );
}

sub _build_s3_bucket {
    my $self = shift;

    return $self->s3_client->bucket( name => $self->bucket_name );
}

sub init {
    my $self = shift;

    $self->s3_client->create_bucket(
        name      => $self->bucket_name,
        acl_short => 'private',
        location_constraint => 'US',
    );
}

sub store {
    my $self = shift;
    my ($path) = pos_validated_list( \@_, { isa => Path } );
    my $asset  = $self->get_asset($path);
    my $object = $self->_asset_object($asset);

    $object->put_filename( $path->filename );

    return $asset;
}

sub is_stored {
    my $self = shift;
    my ($asset) = pos_validated_list( \@_, { isa => Asset } );
    my $object = $self->_asset_object($asset);
    return $object->exists;
}

sub attach {
    my $self = shift;
    my ($path, $asset) = pos_validated_list( \@_, { isa => Path}, { isa => Asset } );

    return if $self->is_attached($path, $asset);

    my $object = $self->_asset_object($asset);
    $object->get_filename($path->filename->stringify) if $object->exists;
}

sub is_attached {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $stat = $path->stat;

    return $stat
        && $stat->size == $asset->size
        && $self->is_stored($asset)
        && $path->digest( $self->digest_type ) eq $asset->checksum;
}

sub remove {
    my $self = shift;
    my ($asset) = pos_validated_list( \@_, { isa => Asset } );
    my $object = $self->_asset_object($asset);
    $object->delete;
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

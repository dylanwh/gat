package Gat::Repository::FS::Copy;
use Gat::Moose;
use namespace::autoclean;

use Gat::Path;
use Gat::Asset;
use Gat::Types ':all';
use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';

with 'Gat::Repository::FS';

sub add {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $asset_path = $self->_asset_path( $asset->checksum );
    my $asset_stat = $asset_path->stat;

    unless ( $asset_stat && -f $asset_stat ) {
        $path->chmod('a-w');
        $path->copy($asset_path);
    }
}

sub attach {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $asset_path = $self->_asset_path($asset->checksum);

    die "asset does not exist: $asset" unless $asset_path->exists;
    if (my $stat = $path->stat) {
        my $dt = $asset->digest_type;
        if ($stat->size != $asset->size && $path->digest($dt) ne $asset->checksum) {
            $path->unlink;
        }
        else {
            return;
        }
    }

    $asset_path->copy($path);
}

sub is_attached {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $asset_path = $self->_asset_path($asset->checksum);

    return $path->exists && $asset_path->exists && $path->digest($asset->digest_type) eq $asset->checksum;
}

__PACKAGE__->meta->make_immutable;

1;

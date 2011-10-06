package Gat::Repository::FS::Symlink;
use Gat::Moose;
use namespace::autoclean;

use Gat::Path;
use Gat::Asset;
use Gat::Types ':all';
use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';

with 'Gat::Repository::FS';

sub store {
    my $self       = shift;
    my ($path)     = pos_validated_list( \@_, { isa => Path } );
    my $asset      = $self->get_asset($path);
    my $asset_path = $self->_asset_path( $asset->checksum );
    my $asset_stat = $asset_path->stat;

    if ($asset_stat && -f $asset_stat) {
        $path->unlink;
        $asset_path->symlink($path);
    }
    else {
        $path->chmod('a-w');
        $path->move($asset_path);
        $asset_path->symlink($path);
    }

    return $asset;
}

sub attach {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $asset_path = $self->_asset_path($asset->checksum);

    die "asset does not exist: $asset" unless $asset_path->exists;
   
    unless ($self->is_attached($path, $asset)) {
        $asset_path->symlink($path);
    }
}

sub is_attached {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $stat       = $path->stat;
    my $asset_path = $self->_asset_path($asset->checksum);

    return 0 unless $stat && -l $stat;
    return 1 if $path->readlink eq $asset_path && $asset_path->exists;
}

__PACKAGE__->meta->make_immutable;

1;

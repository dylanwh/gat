package Gat::Repository::FS::Link;
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

    if ( $asset_stat && -f $asset_stat ) {
        $path->unlink;
        $asset_path->link( $path );
    }
    else {
        $path->chmod('a-w');
        $path->link($asset_path);
    }

    return $asset;
}

sub attach {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $stat       = $path->stat;
    my $asset_path = $self->_asset_path($asset->checksum);
    my $asset_stat = $asset_path->stat;

    die "asset does not exist: $asset" unless $asset_stat;
    return if $self->_stats_eq($stat, $asset_stat); # attached.
    
    $asset_path->link($path);
}

sub is_attached {
    my $self = shift;
    my ( $path, $asset ) = pos_validated_list( \@_, { isa => Path }, { isa => Asset } );
    my $asset_path = $self->_asset_path($asset->checksum);

    return $self->_stats_eq( $path->stat, $asset_path->stat );
}

sub _stats_eq {
    my $self = shift;
    my ( $stat, $asset_stat ) = pos_validated_list(
        \@_,
        { isa => Maybe [FileStat] },
        { isa => Maybe [FileStat] },
    );

    return 0 unless $stat && $asset_stat;
    return
           $stat->ino == $asset_stat->ino
        && $stat->dev == $asset_stat->dev
        && $stat->size == $asset_stat->size;
}

__PACKAGE__->meta->make_immutable;

1;

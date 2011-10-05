package Gat::Repository::FS::Copy;
use Moose;
use namespace::autoclean;

use Gat::Path;
use Gat::Types ':all';
use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';

with 'Gat::Repository::FS';

sub store {
    my $self = shift;
    my ($path)     = pos_validated_list(\@_, { isa => Path });
    my $stat       = $path->stat or die "$path does not exist";
    my $checksum   = $self->get_digest($path);
    my $asset_path = $self->_asset_path($checksum);
    my $asset_stat = $asset_path->stat;

    die "$path is not regular file" unless -f $stat;
    
    unless ($asset_stat && -f $asset_stat) {
        $path->chmod('a-w');
        $path->copy($asset_path);
    }

    return ($stat, $checksum) 
}

sub attach {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );
    my $stat       = $path->stat;
    my $asset_path = $self->_asset_path($checksum);
    my $asset_stat = $asset_path->stat;

    die "asset does not exist: $checksum" unless $asset_stat;
    return if $stat && $self->get_digest($path) eq $checksum;
    
    $path->unlink if $stat;
    $asset_path->copy($path);
}

sub is_attached {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );
    my $asset_path = $self->_asset_path($checksum);

    return $path->exists && $asset_path->exists && $self->get_digest( $path ) eq $checksum;
}

__PACKAGE__->meta->make_immutable;

1;

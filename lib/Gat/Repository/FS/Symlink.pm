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
    my $self = shift;
    my ($path)     = pos_validated_list(\@_, { isa => Path });
    my $stat       = $path->stat or die "$path does not exist";
    my $checksum   = $self->get_digest($path);
    my $asset_path = $self->_asset_path($checksum);
    my $asset_stat = $asset_path->stat;

    die "$path is not regular file" unless -f $stat;
    
    unless ($asset_stat && -f $asset_stat) {
        $path->chmod('a-w');
        $path->move($asset_path);
        $asset_path->symlink($path);
    }

    return Gat::Asset->new(
        mtime    => $stat->mtime,
        size     => $stat->size,
        checksum => $checksum,
    );
}

sub attach {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );
    my $asset_path = $self->_asset_path($checksum);

    die "asset does not exist: $checksum" unless $asset_path->exists;
   
    unless ($self->is_attached($path, $checksum)) {
        $asset_path->symlink($path);
    }
}

sub is_attached {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );
    my $stat       = $path->stat;
    my $asset_path = $self->_asset_path($checksum);

    return 0 unless $stat && -l $stat;
    return 1 if $path->readlink eq $asset_path && $asset_path->exists;
}

__PACKAGE__->meta->make_immutable;

1;

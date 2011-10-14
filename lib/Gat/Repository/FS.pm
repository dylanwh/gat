package Gat::Repository::FS;
use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Types ':all';
use Gat::Path;

# Invariant: asset dir is always 'asset' under the .gat dir
has 'asset_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    init_arg => undef,
    lazy     => 1,
    default  => sub { $_[0]->gat_dir->subdir('asset') },
);

with 'Gat::Repository::API';

sub init {
    shift->asset_dir->mkpath
}

sub remove {
    my $self       = shift;
    my ($asset)    = pos_validated_list( \@_, { isa => Asset } );
    my $asset_path = $self->_asset_path( $asset->checksum );

    die "asset does not exist: $asset" unless $asset_path->exists;
    $asset_path->unlink;
}

sub clone {
    my $self       = shift;
    my ($asset)    = pos_validated_list(\@_, { isa => Asset });
    my $asset_path = $self->_asset_path($asset->checksum);

    die "asset does not exist: $asset" unless $asset_path->exists;

    my $tmp_path   = Gat::Path->new(
        $self->asset_dir->subdir('tmp')->file( $asset->checksum )
    );

    $asset_path->copy( $tmp_path );

    return $tmp_path;
}

sub is_valid {
    my $self       = shift;
    my ($asset)    = pos_validated_list(\@_, { isa => Asset });
    
    return $self->_asset_path($asset->checksum)->exists;
}

sub _asset_path {
    my ($self, $checksum) = @_;

    Gat::Path->new(
        $self->asset_dir->file(
            substr($checksum, 0, 2),
            substr($checksum, 2)
        )
    );
}

1;

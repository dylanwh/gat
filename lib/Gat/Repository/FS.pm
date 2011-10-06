package Gat::Repository::FS;
use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Types ':all';
use Gat::Path;

has 'asset_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

with 'Gat::Repository';

sub init { shift->asset_dir->mkpath }

sub detach {
    my $self = shift;
    my ($path, $asset) = pos_validated_list(\@_, { isa => Path }, { isa => Asset });

    if ($self->is_attached($path, $asset)) {
        $path->unlink; # path must exist of ->is_attached() returned true.
    }
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

sub is_stored {
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

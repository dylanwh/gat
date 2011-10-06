package Gat::Repository;
use Moose::Role;
use namespace::autoclean;

use Gat::Types ':all';
use MooseX::Types;
use MooseX::Params::Validate;

use Gat::Asset;

has 'digest_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# digests are cached
has 'cache' => (
    is       => 'ro',
    isa      => 'CHI::Driver',
    required => 1,
);

has 'file_mmagic' => (
    is      => 'ro',
    isa     => duck_type( ['checktype_filename'] ),
    default => sub { require File::MMagic; File::MMagic->new },
    lazy    => 1,
);

requires qw[ init store remove attach is_attached clone is_stored ];

# init()
# store(Path $path) -> Asset
# attach(Path $path, Asset $asset)
# detach(Path $path, Asset $asset)
sub detach {
    my $self = shift;
    my ($path, $asset) = pos_validated_list(\@_, { isa => Path }, { isa => Asset });

    if ($self->is_attached($path, $asset)) {
        $path->unlink; # path must exist of ->is_attached() returned true.
    }
}

# is_attached(Path $path, Asset $asset)
# remove(Asset $asset)
# is_stored(Asset $asset) -> Bool
# clone(Asset $asset) -> Path -- for editing files

# get_asset(Path $path) -> Asset
sub get_asset { 
    my $self = shift;
    my ($path) = pos_validated_list( \@_, { isa => Path } );

    my $mm   = $self->file_mmagic;
    my $dt   = $self->digest_type;
    my $stat = $path->stat;

    die "$path does not exist"      unless $stat;
    die "$path is not regular file" unless -f $stat;

    return $self->cache->compute(
        [ 'asset', $path->stringify ],
        {   
            expires_in => '1min',
            expire_if  => sub {
                my $stat = $path->stat;
                return !$stat || $_[0]->created_at < $path->stat->mtime;
            },
        },
        sub {
            Gat::Asset->new(
                content_type => $mm->checktype_filename( $path->filename ),
                checksum     => $path->digest($dt),
                mtime        => $stat->mtime,
                size         => $stat->size,
            );
        }
    );
}

1;

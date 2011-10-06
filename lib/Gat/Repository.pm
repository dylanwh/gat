package Gat::Repository;
use Moose::Role;
use namespace::autoclean;

use Gat::Types ':all';
use MooseX::Params::Validate;

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

requires qw[ init store remove attach detach is_attached clone ];

# init()
# store(Path $path) -> (FileStat, Checksum)
# attach(Path $path, Checksum $checksum)
# detach(Path $path, Checksum $checksum)
# is_attached(Path $path, Checksum $checksum)
# remove(Checksum $checksum)
# clone(Checksum $checksum) -> Path -- for editing files

# get_digest(Path $path) -> Checksum
sub get_digest {
    my $self = shift;
    my ($path) = pos_validated_list( \@_, { isa => Path } );

    return $self->cache->compute(
        [ 'digest', $path->stringify ],
        {   
            expires_in => '1min',
            expire_if  => sub {
                my $stat = $path->stat;
                return !$stat || $_[0]->created_at < $path->stat->mtime;
            },
        },
        sub { $path->digest( $self->digest_type ) }
    );
}

1;

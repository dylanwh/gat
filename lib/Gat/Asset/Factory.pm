package Gat::Asset::Factory;
use Moose;
use namespace::autoclean;

use MooseX::Params::Validate;
use Gat::Asset;
use Gat::Types 'Path';

has 'digest_type' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'MD5',
);

has 'cache' => (
    is       => 'ro',
    isa      => 'CHI::Driver',
    required => 1,
);

has 'file_mmagic' => (
    is       => 'ro',
    isa      => 'File::MMagic',
    required => 1,
);

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
                digest_type  => $dt,
                checksum     => $path->digest($dt),
                mtime        => $stat->mtime,
                size         => $stat->size,
            );
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

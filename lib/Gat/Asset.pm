package Gat::Asset;
use Gat::Moose;
use namespace::autoclean;

use MooseX::Types::Moose 'Int';
use MooseX::Types::DateTime 'DateTime';
use Gat::Types 'Checksum';

has 'checksum' => (
    is       => 'rw',
    isa      => Checksum,
    required => 1,
);

has 'digest_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'size' => (
    is       => 'rw',
    isa      => Int,
    required => 1,
);

has 'mtime' => (
    is       => 'rw',
    isa      => DateTime,
    required => 1,
    coerce   => 1,
);

has 'content_type' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'application/octet-stream',
);

__PACKAGE__->meta->make_immutable;

1;

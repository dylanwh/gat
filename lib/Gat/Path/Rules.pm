package Gat::Path::Rules;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Structured 'Tuple';
use MooseX::Storage;

with Storage('format' => 'YAML', 'io' => 'File');

has 'predicates' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [RegexpRef, Bool] ],
    reader  => '_predicates',
    handles => { 'predicates' => 'elements' },
    default => sub { [] },
);

has 'default' => (
    is       => 'ro',
    isa      => Bool,
    default  => 1,
);

__PACKAGE__->meta->make_immutable;
1;

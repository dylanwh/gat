package Gat::Config;
use Gat::Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use MooseX::Storage;
use MooseX::Types::Moose ':all';

with Storage(
    format => [ JSONpm => { json_opts => { pretty => 1 } } ],
    io     => 'File',
);

has 'digest_type' => (
    is      => 'rw',
    isa     => Str,
    default => 'MD5',
);

has 'format' => (
    is      => 'rw',
    isa     => Str,
    default => 'FS::Link',
);

around ['store', 'load'] => sub {
    my ($method, $self, $file) = @_;
    $self->$method("$file");
};

sub init { $_[0]->new->store($_[1]) }

__PACKAGE__->meta->make_immutable;
1;

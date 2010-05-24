package Gat::Types;
use MooseX::Types -declare => [qw[ Label Asset Checksum ]];
use MooseX::Types::Moose ':all';

our $VERSION = 0.001;
our $AUTHORITY = 'cpan:DHARDISON';


class_type Label, { class => 'Gat::Schema::Label' };
class_type Asset, { class => 'Gat::Schema::Asset' };

subtype Checksum, as Str,
    where { length $_ > 2 };

1;

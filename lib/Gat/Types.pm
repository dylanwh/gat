package Gat::Types;
use MooseX::Types -declare => [qw[ Name Asset ]];

our $VERSION = 0.001;
our $AUTHORITY = 'cpan:DHARDISON';


class_type Name, { class => 'Gat::Schema::Name' };
class_type Asset, { class => 'Gat::Schema::Asset' };

1;

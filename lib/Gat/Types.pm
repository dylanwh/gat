package Gat::Types;
use MooseX::Types -declare => [
    qw[ 
        Label Asset Checksum
        AbsoluteDir AbsoluteFile
        RelativeDir RelativeFile
    ]
];
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';

our $VERSION = 0.001;
our $AUTHORITY = 'cpan:DHARDISON';


class_type Label, { class => 'Gat::Schema::Label' };
class_type Asset, { class => 'Gat::Schema::Asset' };

subtype Checksum, as Str,
    where { length $_ > 2 };


subtype AbsoluteDir, as Dir,   where { $_->is_absolute };
coerce  AbsoluteDir, from Dir, via   { $_->absolute };
coerce  AbsoluteDir, from Str, via   { Path::Class::Dir->new($_)->absolute };

subtype AbsoluteFile, as File,   where { $_->is_absolute };
coerce  AbsoluteFile, from File, via   { $_->absolute };
coerce  AbsoluteFile, from Str, via    { Path::Class::File->new($_)->absolute };


subtype RelativeDir, as Dir,   where { $_->is_relative };
coerce  RelativeDir, from Dir, via   { $_->relative };
coerce  RelativeDir, from Str, via   { Path::Class::Dir->new($_)->relative };

subtype RelativeFile, as File,   where { $_->is_relative };
coerce  RelativeFile, from File, via   { $_->relative };
coerce  RelativeFile, from Str,  via   { Path::Class::File->new($_)->relative };




1;

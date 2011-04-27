package Gat::Types;
use MooseX::Types -declare => [
    qw[ 
        Label
        Asset
        Checksum
        Path
        Remote
        RelativeFile
        AbsoluteFile
    ]
];

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';
use Path::Class;

class_type Label, { class => 'Gat::Label' };
class_type Asset, { class => 'Gat::Asset' };
class_type Path,  { class => 'Gat::Path'  };
role_type  Remote, { class => 'Gat::Remote' };

subtype Checksum, as Str, where { length $_ > 2 };

subtype RelativeFile, as File, where { $_->is_relative };
coerce RelativeFile, from Str, via { file($_) };

subtype AbsoluteFile, as File, where { $_->is_absolute };
coerce AbsoluteFile, from Str, via { file($_) };

1;

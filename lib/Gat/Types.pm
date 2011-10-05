package Gat::Types;
use MooseX::Types -declare => [
    qw[ 
        Path
        PathStream
        FileStat

        Remote

        RelativeFile
        AbsoluteFile
        AbsoluteDir

        Checksum
        AttachMethod
        StoreMethod
    ]
];

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';
use Path::Class;


class_type Path,         { class => 'Gat::Path'         };
class_type PathStream,   { class => 'Gat::Path::Stream' };
class_type FileStat,     { class => 'File::stat'        };
role_type  Remote,       { class => 'Gat::Remote' };

subtype Checksum, as Str, where { /^[0-9A-Fa-f]{3,}$/ };

subtype RelativeFile, as File, where { $_->is_relative };
coerce RelativeFile, from Str, via { file($_) };

subtype AbsoluteFile, as File, where { $_->is_absolute };
coerce AbsoluteFile, from Str, via { file($_) };

subtype AbsoluteDir, as Dir, where { $_->is_absolute };
coerce AbsoluteDir, from Str, via { dir($_) };

enum AttachMethod, qw[ link symlink copy ];
enum StoreMethod, qw[ link move copy ];

1;

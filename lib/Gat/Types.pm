package Gat::Types;
use MooseX::Types -declare => [
    qw[ 
        Path
        Label
        Asset
        PathStream
        FileStat

        RelativeFile
        AbsoluteFile
        AbsoluteDir

        Checksum
    ]
];

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';
use Path::Class;


class_type Path,         { class => 'Gat::Path'         };
class_type PathStream,   { class => 'Gat::Path::Stream' };
class_type FileStat,     { class => 'File::stat'        };
class_type Label,        { class => 'Gat::Label'         };
class_type Asset,        { class => 'Gat::Asset'         };

class_type  'Gat::Schema::Result::Label';
class_type  'Gat::Schema::Result::Asset';
class_type  'Gat::Schema';

coerce Label, from 'Gat::Schema::Result::Label', 
    via { Gat::Label->new($_->filename) };

coerce Asset, from 'Gat::Schema::Result::Asset', via {
    Gat::Asset->new(
        checksum     => $_->checksum,
        mtime        => $_->mtime,
        size         => $_->size,
        content_type => $_->content_type,
    );
};

subtype Checksum, as Str, where { /^[0-9A-Fa-f]{3,}$/ };

subtype RelativeFile, as File, where { $_->is_relative };
coerce RelativeFile, from Str, via { file($_) };

subtype AbsoluteFile, as File, where { $_->is_absolute };
coerce AbsoluteFile, from Str, via { file($_) };

subtype AbsoluteDir, as Dir, where { $_->is_absolute };
coerce AbsoluteDir, from Str, via { dir($_) };

1;

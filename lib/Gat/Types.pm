package Gat::Types;
use MooseX::Types -declare => [
    qw[ 
        Label Asset  Checksum
        Remote
        Path
        AbsoluteDir  AbsoluteFile
        RelativeDir  RelativeFile
        AbsolutePath RelativePath
    ]
];

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';

use Path::Class;

class_type Label, { class => 'Gat::Schema::Label' };
class_type Asset, { class => 'Gat::Schema::Asset' };
class_type Path,  { class => 'Path::Class::Entity' };
role_type  Remote, { class => 'Gat::Remote' };

subtype Checksum, as Str, where { length $_ > 2 };

subtype AbsoluteDir,
    as Dir, 
    where { $_->is_absolute },
    message { "$_ is not absolute dir" };

subtype RelativeDir,
    as Dir,
    where { $_->is_relative },
    message { "$_ is not relative dir" };

subtype AbsoluteFile,
    as File,
    where { $_->is_absolute },
    message { "$_ is not absolute file" };

subtype RelativeFile,
    as File,
    where { $_->is_relative },
    message { "$_ is not relative file" };

subtype AbsolutePath,
    as Path,
    where { $_->is_absolute },
    message { "$_ is not absolute path" };

subtype RelativePath,
    as Path,
    where { $_->is_relative },
    message { "$_ is not absolute path" };

coerce AbsoluteDir, from Str, via { dir($_) };
coerce RelativeDir, from Str, via { dir($_) };
coerce AbsoluteFile, from Str,  via { file($_) };
coerce RelativeFile, from Str, via { file($_) };
coerce AbsolutePath, from Str, via { file($_) };
coerce RelativePath, from Str, via { file($_) };

coerce AbsoluteDir, from AbsoluteFile, via { dir($_) };
coerce RelativeDir, from RelativeFile, via { dir($_) };
coerce AbsoluteFile, from AbsoluteDir,  via { file($_) };
coerce RelativeFile, from RelativeDir, via { file($_) };

1;

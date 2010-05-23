use MooseX::Declare;

class Gat::Schema::Name with KiokuDB::Role::ID {
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Path::Class 'File';
    use MooseX::Types::Moose ':all';

    has 'filename' => (
        is       => 'ro',
        isa      => File,
        coerce   => 1,
        required => 1,
    );

    has 'asset' => (
        is       => 'rw',
        isa      => 'Gat::Schema::Asset',
        required => 1,
        weak_ref => 1,
        handles => ['checksum'],
    );

    method kiokudb_object_id {
        return 'name:' . $self->filename;
    }
}

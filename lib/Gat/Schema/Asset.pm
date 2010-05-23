use MooseX::Declare;

class Gat::Schema::Asset with KiokuDB::Role::ID {
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Path::Class 'File';
    use MooseX::Types::Moose ':all';
    use KiokuDB::Util qw( weak_set set );

    use Gat::Types 'Name';

    has '_names' => (
        is       => 'ro',
        init_arg => undef,
        default  => sub { set() },
    );

    has 'checksum' => (
        is       => 'rw',
        isa      => Str,
        required => 1,
    );

    method names() {
        my @names = $self->_names->members;
        return wantarray ? @names : \@names;
    }

    method files() {
        my @files = map { $_->filename } $self->_names->members;
        return wantarray ? @files : \@files;
    }

    method add_name(Name $name) {
        $self->_names->insert($name);
    }

    method del_name(Name $name) {
        $self->_names->remove($name);
    }

    method has_name(Name $name) {
        return $self->_names->contains($name);
    }

    method kiokudb_object_id {
        return 'asset:' . $self->checksum;
    }
}

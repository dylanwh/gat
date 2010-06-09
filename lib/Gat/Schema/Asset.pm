use MooseX::Declare;

class Gat::Schema::Asset
    with KiokuDB::Role::ID
{
    use MooseX::Types::Path::Class 'File';
    use MooseX::Types::Moose ':all';
    use KiokuDB::Util qw( weak_set set );

    use Gat::Types 'Label', 'Checksum';

    has '_labels' => (
        is       => 'ro',
        init_arg => undef,
        default  => sub { set() },
    );

    has 'checksum' => (
        is       => 'rw',
        isa      => Checksum,
        required => 1,
    );

    method files() {
        my @files = map { $_->filename } $self->_labels->members;
        return wantarray ? @files : \@files;
    }

    method add_label(Label $name) {
        $self->_labels->insert($name);
    }

    method remove_label(Label $name) {
        $self->_labels->remove($name);
    }

    method has_label(Label $name) {
        return $self->_labels->contains($name);
    }

    method kiokudb_object_id {
        return 'asset:' . $self->checksum;
    }
}

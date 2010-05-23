use 5.10.1;
use MooseX::Declare;

class Gat::Manifest {
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use Cwd;
    use MooseX::Types::Path::Class 'File', 'Dir';

    has 'file' => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
    );

    has 'digest_type' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'MD5',
    );

    method compute_checksum(File $filename is coerce) {
        my $fh         = $filename->openr;
        my $digest     = Digest->new($self->digest_type);
        $digest->addfile($fh);
        return $digest->hexdigest;
    }

    method find_checksum(File $filename is coerce) {

    }


}

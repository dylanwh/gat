use 5.10.0;
use MooseX::Declare;

class Gat::Config {
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::StrictConstructor;
    use MooseX::Storage;
    use MooseX::Types::Moose ':all';
    use MooseX::Types::Structured 'Tuple';

    with Storage(
        io     => 'File',
        format => [ JSONpm => { json_opts => { pretty => 1 } } ],
    );

    has 'digest_type' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'MD5',
    );

    has 'use_symlinks' => (
        is      => 'ro',
        isa     => 'Bool',
        default => 1,
    );

    has 'rules' => (
        is      => 'ro',
        isa     => ArrayRef [ Tuple [ Str, Bool ] ],
        default => sub { [] },
    );

}

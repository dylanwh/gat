use 5.10.0;
use MooseX::Declare;

class Gat::Error extends Throwable::Error is mutable {
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

}

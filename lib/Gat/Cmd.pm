use MooseX::Declare;

class Gat::Cmd
    extends MooseX::App::Cmd
{
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    method api() { return $self->fetch('api')->get }
}

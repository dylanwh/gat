use MooseX::Declare;

class Gat::Cmd
    extends MooseX::App::Cmd
{
    method api() { return $self->fetch('api')->get }
}

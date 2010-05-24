use feature 'say';
use MooseX::Declare;

class Gat::Cmd::Command::add
    extends Gat::Cmd::Command
{
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use Gat::API;
    use Path::Class;

    method invoke(Gat::API $api, @args) {
        $api->add( [ map { file($_) } @args ] );
    }
}

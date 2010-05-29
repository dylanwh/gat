use feature 'say';
use MooseX::Declare;

class Gat::Cmd::Command::manifest
    extends Gat::Cmd::Command
{
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use Gat;
    use Path::Class;

    method invoke(Gat $gat, @args) {
        my $model  = $gat->model;
        my $stream = $model->manifest;
        until ( $stream->is_done ) {
            for my $item ( $stream->items ) {
                printf "%s  %s\n", @$item;
            }
        }
    }
}


use MooseX::Declare;

class Gat::Cmd::Command
    extends MooseX::App::Cmd::Command 
    with MooseX::Getopt::Dashes 
{
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use Gat::Container;
    use Cwd;
    use MooseX::Types::Path::Class 'Dir';

    has 'container' => (
        traits     => ['NoGetopt'],
        is         => 'ro',
        isa        => 'Gat::Container',
        lazy_build => 1,
    );

    has 'directory' => (
        is      => 'ro',
        isa     => Dir,
        coerce  => 1,
        default => sub {cwd},
    );


    method _build_container { 
        return Gat::Container->new(
            directory => $self->directory,
        );
    }

    method execute(HashRef $opts, ArrayRef $args) {
        my $api = $self->container->fetch('api')->get;
        $api->txn_do(
            sub {
                $self->invoke($api, @$args);
            }
        );
    }

}

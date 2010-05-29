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
        handles    => ['app'],
    );

    has 'directory' => (
        traits  => [ 'Getopt' ],
        is      => 'ro',
        isa     => Dir,
        coerce  => 1,
        default => sub {cwd},
        cmd_aliases => ['C'],
    );


    method _build_container { 
        return Gat::Container->new(
            work_dir => $self->directory,
        );
    }

    method execute(HashRef $opts, ArrayRef $args) {
        my $gat = $self->app;
        $gat->txn_do(
            sub {
                $self->invoke($gat, @$args);
            }
        );
    }

}

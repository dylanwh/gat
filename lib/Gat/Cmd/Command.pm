use MooseX::Declare;

class Gat::Cmd::Command
    extends MooseX::App::Cmd::Command 
    with MooseX::Getopt::Dashes 
{
    use TryCatch;
    use Cwd;
    use MooseX::Types::Path::Class 'Dir';

    use Gat::Container;

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
        try {
            $gat->txn_do(
                sub {
                    $self->invoke($gat, @$args);
                }
            );
        }
        catch (Gat::Error $err) {
            warn $err->message, "\n";
            exit 1;
        }
    }

}

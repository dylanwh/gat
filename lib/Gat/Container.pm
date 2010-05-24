use 5.10.0;
use MooseX::Declare;

class Gat::Container
    extends Bread::Board::Container
{
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use TryCatch;
    use Bread::Board;
    use MooseX::Types::Path::Class 'Dir';

    use Gat::Store;
    use Gat::Model;
    use Gat::Config;
    use Gat::API;

    has '+name' => ( default => 'Gat' );

    has 'directory' => (
        is       => 'ro',
        isa      => Dir,
        coerce   => 1,
        required => 1,
    );

    method BUILD {
        my $work_dir    = $self->directory;
        my $gat_dir     = $work_dir->subdir('.gat');
        my $store_dir   = $gat_dir->subdir('store');
        my $model_dir   = $gat_dir->subdir('model');
        my $config_file = $gat_dir->file('config');

        $gat_dir->mkpath;
        
        container $self => as {
            service 'config_file' => $config_file;
            service 'storage_dir' => $store_dir;
            service 'work_dir'    => $work_dir;

            service 'dsn'         => 'bdb:dir=' . $model_dir->absolute;
            service 'extra_args'  => { create => 1 };

            service 'digest_type' => (
                block => sub {
                    my $s = shift;
                    return $s->param('config')->digest_type;
                },
                dependencies => wire_names('config'),
            );
            
            service 'rules' => (
                block => sub {
                    my $s = shift;
                    return [ map { [ qr/$_->[0]/ => $_->[1] ] } @{ $s->param('config')->rules } ];
                },
                dependencies => wire_names('config'),
            );

            service 'config' => (
                block => sub {
                    my $s = shift;

                    my $config;
                    try {
                        $config = Gat::Config->load(
                            $s->param('config_file') . "",
                        );
                    }
                    catch (Any $e) {
                        $config = Gat::Config->new;
                    }
                    return $config;
                },
                dependencies => wire_names('config_file'),
            );

            service store => (
                class        => 'Gat::Store',
                lifecycle    => 'Singleton',
                dependencies => wire_names( qw[ digest_type storage_dir work_dir rules ]),
            );

            service model => (
                class        => 'Gat::Model',
                lifecycle    => 'Singleton',
                dependencies => wire_names(qw[ dsn extra_args ]),
            );

            service api => (
                class        => 'Gat::API',
                lifecycle    => 'Singleton',
                dependencies => wire_names(qw[ model store config config_file ]),
            );
        };
    }

}

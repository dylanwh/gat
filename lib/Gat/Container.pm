use 5.10.0;
use MooseX::Declare;

class Gat::Container
    extends Bread::Board::Container
{
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use Bread::Board;
    use MooseX::Types::Path::Class 'Dir';

    use Gat;
    use Gat::Storage::Directory;
    use Gat::Types ':all';

    has '+name' => ( default => 'Gat' );

    has 'work_dir' => (
        is       => 'ro',
        isa      => AbsoluteDir,
        coerce   => 1,
        required => 1,
    );

    method BUILD {
        my $work_dir = $self->work_dir;
        my $gat_dir  = $work_dir->subdir('.gat');

        $gat_dir->mkpath;
        
        container $self => as {
            container "config" => as {
                service digest_type  => 'MD5';
                service use_symlinks => 1;
                service rules        => [];
                service rule_default => 1;
            };

            container database => as {
                service dsn        => 'bdb:dir=' . $gat_dir->subdir('model');
                service extra_args => { create => 1 };
                service model => (
                    class        => 'Gat::Model',
                    lifecycle    => 'Singleton',
                    dependencies => wire_names(qw[ dsn extra_args ]),
                );
            };

            container filesystem => as {
                service work_dir     => $work_dir;
                service gat_dir      => $gat_dir;
                service storage_dir  => $gat_dir->subdir('storage');

                service storage => (
                    class        => 'Gat::Storage::Directory',
                    dependencies => {
                        digest_type  => depends_on('/config/digest_type'),
                        use_symlinks => depends_on('/config/use_symlinks'),
                        storage_dir  => depends_on('storage_dir'),
                    },
                );

                service selector => (
                    class        => 'Gat::Selector',
                    dependencies => {
                        work_dir     => depends_on('work_dir'),
                        gat_dir      => depends_on('gat_dir'),
                        rules        => depends_on('/config/rules'),
                        rule_default => depends_on('/config/rule_default'),
                    },
                );
            };

            service app => (
                class        => 'Gat',
                lifecycle    => 'Singleton',
                dependencies => {
                    storage   => depends_on('filesystem/storage'),
                    selector  => depends_on('filesystem/selector'),
                    model     => depends_on('database/model'),
                },
            );

            my $config_file = $gat_dir->file('config');
            include $config_file if -f $config_file;
        };
    }

    method app { $self->fetch('app')->get }
}

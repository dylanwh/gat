package Gat::Container;
use Moose;
use namespace::autoclean;

extends 'Bread::Board::Container';

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

sub BUILD {
    my ($self)   = @_;
    my $work_dir = $self->work_dir;
    my $gat_dir  = $work_dir->subdir('.gat');

    $gat_dir->mkpath;
    
    container $self => as {
        service dsn        => 'bdb:dir=' . $gat_dir->subdir('model');
        service extra_args => { create => 1 };
        service model => (
            class        => 'Gat::Model',
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw[ dsn extra_args ]),
        );

        service digest_type  => 'MD5';
        service use_symlinks => 1;
        service storage_dir  => $gat_dir->subdir('storage');
        service storage => (
            class        => 'Gat::Storage::Directory',
            dependencies => wire_names(qw[ digest_type use_symlinks storage_dir ]),
        );

        service work_dir     => $work_dir;
        service gat_dir      => $gat_dir;
        service rules        => [];
        service rule_default => 1;
        service selector => (
            class        => 'Gat::Selector',
            dependencies => wire_names(qw[ work_dir gat_dir rules rule_default ]),
        );

        service app => (
            class        => 'Gat',
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw[ storage selector model work_dir ]),
        );

        my $config_file = $gat_dir->file('config');
        include $config_file if -f $config_file;
    };
}

sub app { $_[0]->fetch('app')->get }

__PACKAGE__->meta->make_immutable;

1;

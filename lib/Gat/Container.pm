package Gat::Container;
use Moose;
use namespace::autoclean;

use Cwd;

use Bread::Board;
use Path::Class;
use Carp;
use MooseX::Types::Path::Class 'Dir';

use Gat::Path;
use Gat::Config;
use Gat::Repository;
use Gat::Model;
use Gat::Types 'AbsoluteDir';
use Gat::Util ':all';

extends 'Bread::Board::Container';

has '+name' => ( default => 'Gat' );

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    predicate => 'has_base_dir',
);

sub check_workspace {
    my ($self) = @_;
    my $gd = $self->fetch('gat_dir')->get;
    my $ok = -d $gd && -f $gd->file('config') && -d $gd->subdir('asset');
    die "Invalid gat workspace (did you forget to run gat init?)\n" unless $ok;
}

sub BUILD {
    my ($self)   = @_;

    container $self => as {
        service work_dir  => $self->work_dir;
        service base_dir => (
            block => sub {
                $self->has_base_dir ? $self->base_dir : find_base_dir( $self->work_dir );
            },
        );
        service gat_dir => (
            block => sub { $_[0]->param('base_dir')->subdir('.gat') },
            dependencies => wire_names('base_dir'),
        );

        service 'predicates' => (
            block => sub {
                my ($p)   = @_;
                my $file  = $p->param('gat_dir')->file('rules');

                return -f $file ? parse_rules($file) : [];
            },
            dependencies => wire_names('gat_dir'),
        );
        service 'path_rules' => (
            class        => 'Gat::Path::Rules',
            dependencies => wire_names(qw[ predicates work_dir base_dir gat_dir ]),
        );

        service config => (
            class        => 'Gat::Config',
            dependencies => wire_names(qw[ gat_dir ]),
        );

        container 'Model' => as {
            service model_dir => (
                block        => sub       { $_[0]->param('gat_dir')->subdir('model') },
                dependencies => { gat_dir => depends_on('/gat_dir') },
            );
            service dsn        => 'bdb';
            service extra_args => (
                block => sub {
                    return {
                        manager => {
                            create => 1,
                            home   => $_[0]->param('model_dir'),
                        },
                    };
                },
                dependencies => wire_names(qw[ model_dir ]),
            );
            service instance => (
                class        => 'Gat::Model',
                dependencies => wire_names(qw[ dsn extra_args ]),
            );
        };

        container 'Repository' => as {
            service asset_dir => (
                block => sub { $_[0]->param('gat_dir')->subdir('asset') },
                dependencies => { gat_dir => depends_on('/gat_dir') },
            );
            service use_symlinks => (
                block => sub {
                    my $cfg = $_[0]->param('config');
                    $cfg->get(key => 'repository.use_symlinks', as => 'bool');
                },
                dependencies => { config => depends_on('/config') },
            );
            service digest_type => (
                block => sub {
                    my $cfg = $_[0]->param('config');
                    $cfg->get(key => 'repository.digest_type');
                },
                dependencies => { config => depends_on('/config') },
            );

            service instance => (
                class        => 'Gat::Repository',
                dependencies => wire_names(qw[ use_symlinks digest_type asset_dir ]),
            );
        };
    };
}

__PACKAGE__->meta->make_immutable;

1;

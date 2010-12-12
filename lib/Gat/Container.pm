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
    lazy     => 1,
    builder => '_build_base_dir',
);

sub _build_base_dir {
    my ($self) = @_;
    my $work = $self->work_dir;
    my $root = dir('');
    my $base = $work;

    until (-d $base->subdir('.gat')) {
        $base = $base->parent;
        return $work if $base eq $root;
    }

    return $base;
}

sub check_workspace {
    my ($self) = @_;
    my $gd = $self->base_dir->subdir('.gat');
    my $ok = -d $gd && -f $gd->file('config') && -d $gd->subdir('asset');
    die "Invalid gat workspace (did you forget to run gat init?)\n" unless $ok;
}

sub BUILD {
    my ($self)   = @_;

    container $self => as {
        service work_dir => $self->work_dir;
        service base_dir => $self->base_dir;

        service Rules => (
            block        => sub {
                require Gat::Rules;
                my $rules = Gat::Rules->new;
                $rules->load( $_[0]->param('base_dir') );
                return $rules;
            },
            dependencies => wire_names(qw[ base_dir ]),
        );

        service Path => (
            class        => 'Gat::Path',
            dependencies => {
                rules    => depends_on('Rules'),
                base_dir => depends_on('base_dir'),
                work_dir => depends_on('work_dir'),
            },
        );

        service Config => (
            block        => sub {
                require Gat::Config;
                my $cfg = Gat::Config->new;
                $cfg->load( $_[0]->param('base_dir') );
                return $cfg;
            },
            dependencies => wire_names(qw[ base_dir ]),
        );

        container 'Model' => as {
            service model_dir => (
                block        => sub { $_[0]->param('base_dir')->subdir('.gat/model') },
                dependencies => { base_dir => depends_on('/base_dir') },
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
                block        => sub       { $_[0]->param('base_dir')->subdir('.gat/asset') },
                dependencies => { base_dir => depends_on('/base_dir') },
            );
            service use_symlinks => (
                block => sub {
                    my $cfg = $_[0]->param('config');
                    $cfg->get( key => 'repository.use_symlinks', as => 'bool' );
                },
                dependencies => { config => depends_on('/Config') },
            );
            service digest_type => (
                block => sub {
                    my $cfg = $_[0]->param('config');
                    $cfg->get( key => 'repository.digest_type' );
                },
                dependencies => { config => depends_on('/Config') },
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

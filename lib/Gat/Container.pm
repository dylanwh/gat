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

        service model_dir => (
            block        => sub { $_[0]->param('base_dir')->subdir('.gat/model') },
            dependencies => { base_dir => depends_on('base_dir') },
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
        service Model => (
            class        => 'Gat::Model',
            dependencies => wire_names(qw[ dsn extra_args ]),
        );

        service asset_dir => (
            block        => sub { $_[0]->param('base_dir')->subdir('.gat/asset') },
            dependencies => { base_dir => depends_on('base_dir') },
        );
        service digest_type => (
            block        => sub { $_[0]->param('config')->get(key => 'repository.digest_type') },
            dependencies => { config => depends_on('Config') },
        );
        service attach_method => (
            block => sub { 
                $_[0]->param('config')->get(key => 'repository.attach_method') || 'symlink'
            },
            dependencies => { config => depends_on('Config') },
        );
        service Repository => (
            class        => 'Gat::Repository',
            dependencies => wire_names(qw[ asset_dir digest_type attach_method ]),
        );

        service 'App' => (
            class        => 'Gat',
            dependencies => {
                config     => depends_on('Config'),
                path       => depends_on('Path'),
                model      => depends_on('Model'),
                repository => depends_on('Repository'),
                base_dir   => depends_on('base_dir'),
            },
        );

    };
}

__PACKAGE__->meta->make_immutable;

1;

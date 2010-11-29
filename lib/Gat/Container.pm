package Gat::Container;
use Moose;
use namespace::autoclean;

use Cwd;

use Bread::Board;
use MooseX::Types::Path::Class 'Dir';

use Gat::Path;
use Gat::Repository::Local;
use Gat::Model;

extends 'Bread::Board::Container';

has '+name' => ( default => 'Gat' );

sub BUILD {
    my ($self)   = @_;

    container $self => as {
        service 'work_dir' => cwd;
        service 'path'     => (
            class        => 'Gat::Path',
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw[ work_dir ]),
        );

        service extra_args => { create => 1 };
        service dsn        => (
            block => sub {
                return 'bdb:dir=' . $_[0]->param('path')->gat_subdir('model');
            },
            dependencies => wire_names(qw[ path ]),
        );
        service model => (
            class        => 'Gat::Model',
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw[ dsn extra_args ]),
        );

        service digest_type  => 'MD5';
        service use_symlinks => $ENV{GAT_USE_SYMLINKS} || 0;
        service asset_dir    => (
            block => sub {
                return $_[0]->param('path')->gat_subdir('asset');
            },
            dependencies => wire_names(qw[ path ]),
        );
        service repository => (
            class        => 'Gat::Repository::Local',
            dependencies => wire_names(qw[ digest_type use_symlinks asset_dir ]),
        );

        container 'command' => as {
            service 'add_options' => (
                block => sub { 
                    require Gat::Command::Add::Options;
                    Gat::Command::Add::Options->new_with_options },
            );

            service 'add' => (
                class => 'Gat::Command::Add',
                dependencies => { 
                    path       => depends_on('/path'),
                    repository => depends_on('/repository'),
                    model      => depends_on('/model'),
                    options    => depends_on('add_options'),
                },
            );
        };
    };
}

__PACKAGE__->meta->make_immutable;

1;

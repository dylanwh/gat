package Gat::Container;
use Moose;
use namespace::autoclean;

use Cwd;

use Bread::Board;
use Carp;
use MooseX::Types::Path::Class 'Dir';

use Gat::Path;
use Gat::Config;
use Gat::Repository;
use Gat::Model;
use Gat::FileStream;
use Gat::Rules;
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
    required => 1,
);

sub BUILD {
    my ($self)   = @_;

    container $self => as {

        service work_dir  => $self->work_dir;
        service base_dir  => $self->base_dir;
        service asset_dir => $self->base_dir->subdir('.gat/asset');
        service model_dsn  => 'bdb';
        service model_args => {
            manager => {
                create => 1,
                home   => $self->base_dir->subdir('.gat/model'),
            },
        };

        typemap 'Gat::Config' => infer(
            dependencies => wire_names(qw[ base_dir ]),
        );

        typemap 'Gat::Rules' => infer(
            dependencies => wire_names(qw[ base_dir ]),
        );

        typemap 'Gat::Path' => infer(
            dependencies => {
                base_dir => depends_on('base_dir'),
                work_dir => depends_on('work_dir'),
            },
        );

        typemap 'Gat::Model' => infer(
            dependencies => {
                dsn        => depends_on('model_dsn'),
                extra_args => depends_on('model_args'),
            },
        );

        typemap 'Gat::FileStream' => infer(
            parameters => { files  => { optional => 0 } },
        );

        typemap 'Gat::Repository' => infer();
    };
}

__PACKAGE__->meta->make_immutable;

1;

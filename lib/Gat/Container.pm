package Gat::Container;
use Gat::Moose;
use namespace::autoclean;

use Cwd;
use Carp;

use Bread::Board;
use CHI;
use CHI::Driver;

use Gat::Constants 'GAT_DIR';
use Gat::Types 'AbsoluteDir';

use Gat;
use Gat::Path;
use Gat::Path::Sieve;
use Gat::Path::Sieve::Util 'load_rules';
use Gat::Path::Stream;
use Gat::Schema;
use Gat::Model;
use Gat::Config;

use Gat::Repository::FS::Link;
use Gat::Repository::FS::Copy;
use Gat::Repository::FS::Symlink;

extends 'Bread::Board::Container';

has '+name' => ( default => 'Gat' );

has 'base_dir' => ( is => 'ro', isa => AbsoluteDir, required => 1 );
has 'work_dir' => ( is => 'ro', isa => AbsoluteDir, required => 1 );

sub BUILD {
    my ($self)   = @_;

    container $self => as {
        service 'base_dir'    => $self->base_dir;
        service 'work_dir'    => $self->work_dir;
        service 'gat_dir'     => $self->base_dir->subdir(GAT_DIR);
        service 'asset_dir'   => $self->base_dir->subdir(GAT_DIR)->subdir('asset');
        service 'config_file' => $self->base_dir->subdir(GAT_DIR)->file('config');
        service 'rules_file' => $self->base_dir->subdir(GAT_DIR)->file('rules');

        service 'digest_type' => (
            block        => sub { $_[0]->param('config')->digest_type },
            dependencies => wire_names('config'),
        );

        service 'dsn' => (
            block => sub {
                my $s = shift;
                return 'dbi:SQLite:dbname=' . $s->param('gat_dir')->file('asset.db');
            },
            dependencies => wire_names('gat_dir'),
        );

        service 'schema' => (
            block => sub {
                my $s = shift;
                Gat::Schema->connect(
                    $s->param('dsn'),
                    undef,
                    undef, 
                    { RaiseError => 1, PrintError => 0, AutoCommit => 1 }
                );
            },
            dependencies => wire_names('dsn'),
        );

        service 'config' => (
            block => sub {
                my $s    = shift;
                my $file = $s->param('config_file');

                return Gat::Config->load($file) if -f $file;
                return Gat::Config->new;
            },
            dependencies => wire_names('config_file'),
            lifecycle    => 'Singleton',
        );

        service 'rules' => (
            block => sub {
                my $s = shift;
                my $file = $s->param('rules_file');
                return -f $file ? load_rules($file) : [];
            },
            dependencies => wire_names('rules_file'),
        );

        service 'repository' => (
            block => sub {
                my $s      = shift;
                my $format = $s->param('format') // $s->param('config')->format;
                my $class  = "Gat::Repository::$format";

                return $s->parent->resolve( type => $class );
            },
            parameters   => { format => { optional => 1 } },
            dependencies => wire_names('config'),
            lifecycle    => 'Singleton::WithParameters',
        );

        service 'cache' => ( block => sub { CHI->new( driver => 'Memory', global => 1 ) }, );

        typemap 'Gat::Repository' => 'repository';
        typemap 'Gat::Config'     => 'config';
        typemap 'Gat::Schema'     => 'schema';
        typemap 'CHI::Driver'     => 'cache';
        typemap 'Gat::Model'      => infer;

        typemap 'Gat::Repository::FS::Link' => infer(
            dependencies => wire_names(qw[ asset_dir digest_type ]),
        );

        typemap 'Gat::Repository::FS::Symlink' => infer(
            dependencies => wire_names(qw[ asset_dir digest_type ]),
        );

        typemap 'Gat::Repository::FS::Copy' => infer(
            dependencies => wire_names(qw[ asset_dir digest_type ]),
        );

        typemap 'Gat::Path::Sieve' => infer(
            dependencies => wire_names(qw[ rules gat_dir asset_dir base_dir ]),
        );

        typemap 'Gat::Path::Stream' => infer(
            dependencies => wire_names(qw[ work_dir ])
        );
    };
}

sub repository {
    my ($self, $format) = @_;

    if ($format) {
        $self->resolve(type => 'Gat::Repository', parameters => { format => $format });
    }
    else {
        $self->resolve(type => 'Gat::Repository');
    }
}

sub model {
    my ($self) = @_;

    $self->resolve(type => 'Gat::Model');
}

sub config {
    my ($self) = @_;

    $self->resolve(type => 'Gat::Config');
}

sub path_stream {
    my ($self, $files) = @_;

    return $self->resolve(type => 'Gat::Path::Stream', parameters => { files => $files });
}

__PACKAGE__->meta->make_immutable;

1;

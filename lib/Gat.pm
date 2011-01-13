# ABSTRACT: A Glorious Asset Tracker

package Gat;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use MooseX::Params::Validate;
use KiokuDB::Cmd::Command::Dump;
use KiokuDB::Cmd::Command::Load;

use Gat::Types ':all';

has 'model' => (
    is       => 'ro',
    isa      => 'Gat::Model',
    required => 1,
);

has 'repository' => (
    is       => 'ro',
    isa      => 'Gat::Repository',
    required => 1,
);

has 'path' => (
    is       => 'ro',
    isa      => 'Gat::Path',
    required => 1,
);

has 'config' => (
    is       => 'ro',
    isa      => 'Gat::Config',
    required => 1,
);

has 'remotes' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [Remote],
    default => sub { {} },
    handles => {
        remote      => 'get',
        has_remotes => 'count',
    },
);

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

sub check_workspace {
    my ($self) = @_;
    my $gd = $self->base_dir->subdir('.gat');
    my $ok = -d $gd && -f $gd->file('config') && -d $gd->subdir('asset');
    die "Invalid gat workspace (did you forget to run gat init?)\n" unless $ok;
}

sub push {
    my $self = shift;
    my ($remote, $checksums) = validated_list(
        \@_,
        remote    => { isa => Str },
        checksums => { does => 'Data::Stream::Bulk', optional => 1 },
    );
}

sub pull {
    my $self = shift;
    my ($remote, $checksums) = validated_list(
        \@_,
        remote    => { isa => Str },
        checksums => { does => 'Data::Stream::Bulk', optional => 1 },
    );
}

sub add {
    my $self = shift;
    my ($verbose, $force, $files) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 1 },
        force   => { isa => Bool, default => 0 },
        files   => { does => 'Data::Stream::Bulk' },
    );
    my $path   = $self->path;
    my $config = $self->config;
    my $model  = $self->model;
    my $repo   = $self->repository;
    my $scope  = $model->new_scope;

    until ($files->is_done) {
        for my $file ($files->items) {
            die "invalid path: $file"    unless $path->is_valid($file);
            die "disallowed path: $file" unless $path->is_allowed($file) or $force;

            my $cfile = $path->canonical($file);
            my $afile = $path->absolute($file);

            my ($checksum, $stat) = $repo->store(file => $afile);
            $repo->attach(
                file     => $afile,
                checksum => $checksum,
                symlink  => $config->get( key => 'repository.use_symlinks', as => 'bool' ),
            );
            $model->add_label($cfile, $checksum, $stat->size);
        }
    }
}

sub print_files {
    my $self = shift;
    my ( $output, $null, $filter ) = validated_list(
        \@_,
        output => { isa => FileHandle, default  => \*STDOUT },
        null   => { isa => Bool,       default  => 0 },
        filter => { isa => CodeRef,    optional => 1 },
    );
    my $path  = $self->path;
    my $model = $self->model;
    my $scope = $model->new_scope;
    my $files = $model->files;

    local $\ = $null ? "\0" : "\n";
    local $, = $\;

    until ($files->is_done) {
        my @files = $filter ? grep &$filter, $files->items : $files->items;
        print $output @files if @files;
    }
}

sub hide {
    my $self = shift;
    my ($verbose, $force, $files) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 1 },
        force   => { isa => Bool, default => 0 },
        files   => { does => 'Data::Stream::Bulk' },
    );
    my $path   = $self->path;
    my $model  = $self->model;
    my $repo   = $self->repository;
    my $scope  = $model->new_scope;

    until ($files->is_done) {
        for my $file ($files->items) {
            die "invalid path: $file"    unless $path->is_valid($file);
            die "disallowed path: $file" unless $path->is_allowed($file) or $force;

            my $cfile = $path->canonical($file);
            my $afile = $path->absolute($file);

            my $label = $model->lookup_label($cfile);
            if ($label) {
                $repo->detach(
                    file     => $afile,
                    checksum => $label->checksum,
                );
            }
        }
    }
}

sub unhide {
    my $self = shift;
    my ($verbose, $force, $files) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 1 },
        force   => { isa => Bool, default => 0 },
    );
    my $path   = $self->path;
    my $config   = $self->config;
    my $model  = $self->model;
    my $repo   = $self->repository;
    my $scope  = $model->new_scope;
    my $stream = $repo->checksums;

    until ($stream->is_done) {
        for my $checksum ($stream->items) {
            my $asset = $model->lookup_asset($checksum);
            for my $file ($asset->files) {
                my $afile = $path->base_dir->file( $file );

                $repo->attach(
                    file=> $afile,
                    checksum => $checksum,
                    symlink  => $config->get( key => 'repository.use_symlinks', as => 'bool' ),
                ) unless -f $afile;
            }
        }
    }
}

sub remove {
    my $self = shift;
    my ( $verbose, $force, $files ) = validated_list(
        \@_,
        verbose => { isa  => Bool, default => 1 },
        force   => { isa  => Bool, default => 0 },
        files   => { does => 'Data::Stream::Bulk' },
    );

    my $path   = $self->path;
    my $config = $self->config;
    my $model  = $self->model;
    my $repo   = $self->repository;
    my $scope  = $model->new_scope;

    until ( $files->is_done ) {
        for my $file ( $files->items ) {
            die "invalid path: $file" unless $path->is_valid($file);
            my $cfile    = $path->canonical($file);
            my $afile    = $path->absolute($file);
            my $checksum = $model->remove_label($cfile);
            
            if (-f $afile) {
                die "Will not detach $file from $checksum without --force" unless $force;
                $repo->detach( file => $afile, checksum => $checksum );
            }
            $repo->remove( checksum => $checksum );
        }
    }
}

sub export_model {
    my $self = shift;
    my ($file) = validated_list( \@_,
        file => { isa => File, coerce => 1, optional => 1 },
    );
    my $model = $self->model;

    my $dumper = KiokuDB::Cmd::Command::Dump->new(
        backend       => $model->directory->backend,
        output_handle => $file ? $file->openw : \*STDOUT,
    );

    $dumper->run;
}

sub import_model {
    my $self = shift;
    my ($file) = validated_list( \@_,
        file => { isa => File, coerce => 1, optional => 1 },
    );
    my $model = $self->model;

    my $loader = KiokuDB::Cmd::Command::Load->new(
        backend       => $model->directory->backend,
        input_handle => $file ? $file->openr : \*STDIN,
    );

    my $scope = $model->new_scope;
    $model->directory->backend->clear();
    $loader->run;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A Glorious Asset Tracker

package Gat;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';

use Path::Class;
use MooseX::Params::Validate;

use KiokuDB::Cmd::Command::Dump;
use KiokuDB::Cmd::Command::Load;

use Gat::Types ':all';
use Gat::Container;

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

has 'base_dir' => (
    is         => 'ro',
    isa        => AbsoluteDir,
    coerce     => 1,
    lazy_build => 1,
);


has 'container' => (
    is         => 'ro',
    isa        => 'Gat::Container',
    required   => 1,
    handles    => [qw[ resolve fetch ]],
    lazy_build => 1,
);

sub _build_container {
    my $self = shift;
    return Gat::Container->new( work_dir => $self->work_dir, base_dir => $self->base_dir );
}

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
    my $ok = -d $gd && -f $gd->file('config');
    die "Invalid gat workspace (did you forget to run gat init?)\n" unless $ok;
}

sub init {
    my $self = shift;
    my ($verbose) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 0 },
    );

    my $c = $self->container;

    my $base_dir = $self->base_dir;
    my $gat_dir  = $base_dir->subdir('.gat');
    $gat_dir->mkpath( $verbose );
    $gat_dir->subdir('model')->mkpath( $verbose );
    $gat_dir->subdir('asset')->mkpath( $verbose );

    my $rules_file = $gat_dir->file('rules');
    $rules_file->openw->print("") unless -f $rules_file;

    my $config      = $c->resolve( type => 'Gat::Config' );
    my $config_file = $gat_dir->file('config');

    unless (-f $config_file) {
        $config->set(
            key      => 'repository.attach_method',
            value    => 'symlink',
            filename => $config_file,
        );

    $config->set(
            key      => 'repository.digest_type',
            value    => 'MD5',
            filename => $config_file,
        );

        $config->set(
            key      => 'repository.asset_dir',
            value    => '.gat/asset',
            filename => $config_file,
        );
    }
}

sub add {
    my $self = shift;
    my ($verbose, $force, $files) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 1 },
        force   => { isa => Bool, default => 0 },
        files   => { does => 'Data::Stream::Bulk' },
    );
    my $path   = $self->resolve(type => 'Gat::Path');
    my $model  = $self->resolve(type => 'Gat::Model');
    my $repo   = $self->resolve(type => 'Gat::Repository');
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
    my $path   = $self->resolve(type => 'Gat::Path');
    my $model  = $self->resolve(type => 'Gat::Model');
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
    my $path   = $self->resolve(type => 'Gat::Path');
    my $model  = $self->resolve(type => 'Gat::Model');
    my $repo   = $self->resolve(type => 'Gat::Repository');
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
    my ( $verbose, $force, $files ) = validated_list(
        \@_,
        verbose => { isa => Bool, default => 1 },
        force   => { isa => Bool, default => 0 },
    );
    my $path  = $self->resolve( type => 'Gat::Path' );
    my $model = $self->resolve( type => 'Gat::Model' );
    my $repo  = $self->resolve( type => 'Gat::Repository' );
    my $scope = $model->new_scope;
    my $stream = $repo->checksums;

    until ( $stream->is_done ) {
        for my $checksum ( $stream->items ) {
            my $asset = $model->lookup_asset($checksum);
            for my $file ( $asset->files ) {
                my $afile = $path->base_dir->file($file);

                $repo->attach(
                    file     => $afile,
                    checksum => $checksum,
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

    my $path   = $self->resolve(type => 'Gat::Path');
    my $model  = $self->resolve(type => 'Gat::Model');
    my $repo   = $self->resolve(type => 'Gat::Repository');
    my $scope  = $model->new_scope;

    until ( $files->is_done ) {
        for my $file ( $files->items ) {
            die "invalid path: $file" unless $path->is_valid($file);
            my $cfile    = $path->canonical($file);
            my $afile    = $path->absolute($file);
           
            my $checksum = $model->find_checksum($cfile);
            if (-f $afile) {
                die "Will not detach $file from $checksum without --force" unless $force;
                $repo->detach( file => $afile, checksum => $checksum );
            }

            $model->remove_label($cfile);
        }
    }
}

sub export_model {
    my $self = shift;
    my ($file) = validated_list( \@_,
        file => { isa => File, coerce => 1, optional => 1 },
    );
    my $model = $self->resolve(type => 'Gat::Model');

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
    my $model = $self->resolve(type => 'Gat::Model');

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

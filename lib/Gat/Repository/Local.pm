package Gat::Repository::Local;

# ABSTRACT: The (default) storage method (store files in $GAT_DIR/storage)

use Moose;
use namespace::autoclean;

use File::Copy::Reliable 'move_reliable';

use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Filter;

use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Types::Moose ':all';

use Gat::Types ':all';
use Gat::Error;

with 'Gat::Repository::API';

has 'storage_dir' => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

has 'use_symlinks' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

sub _resolve_safe {
    my ($self, $checksum) = @_;
    my $prefix = substr($checksum, 0, 2);
    return $self->storage_dir->subdir($prefix)->subdir($checksum);
}

sub _resolve {
    my ($self, $checksum) = @_;
    my $file = $self->_resolve_safe($checksum);
    Gat::Error->throw( message => "missing asset $file" )  unless -f $file;
    return $file;
}

sub insert {
    my ($self, $file) = @_;
    Gat::Error->throw(message => "$file does not exist")        unless -e $file;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;

    my $checksum   = $self->compute_checksum($file);
    my $asset_file = $self->_resolve_safe($checksum);

    if (-f $asset_file) { # already have that, so remove it.
        unlink($file);
    }
    else {                                   # don't have it
        $asset_file->parent->mkpath;         # ensure path exists
        move_reliable($file, $asset_file);   # move the file over.
    }

    return $checksum;
}

sub link {
    my ($self, $file, $checksum) = @_;

    Gat::Error->throw( message => "Can't overwrite $file" ) if -e $file;

    my $asset_file = $self->_resolve($checksum);
    $file->parent->mkpath;

    if ($self->use_symlinks) {
        symlink( $asset_file->relative($file->parent), $file );
    }
    else {
        link( $asset_file, $file);
    }
}

sub unlink {
    my ($self, $file, $checksum) = @_;

    Gat::Error->throw(message => "$file does not exist")        unless -e $file;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;

    my $asset_file = $self->_resolve($checksum);
    if ($self->compute_checksum($file) ne $checksum) {
        Gat::Error->throw( message => "Cannot unlink unmanaged file: $file" );
    }
    unlink( $file );
}

sub verify {
    my ($self, $file, $checksum) = @_;


    return undef unless -f $file;
    return undef unless -f $self->_resolve_safe($checksum);
    return 0 if $self->compute_checksum($file) ne $checksum;
    return 1;
}

sub assets {
    my ($self) = @_;

    return Data::Stream::Bulk::Filter->new(
        filter => sub { [ map { $_->basename } @$_ ] },
        stream => Data::Stream::Bulk::Path::Class->new(
            dir        => $self->storage_dir,
            only_files => 1,
        ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

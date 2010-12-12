package Gat::Repository;

# ABSTRACT: The (default) asset method (store files in $GAT_DIR/asset)
use Moose;
use namespace::autoclean;
use strictures 1;
use autodie;

use File::Copy::Reliable 'move_reliable';
use File::Basename;
use File::stat;
use File::chmod;
use Digest;
use Carp;

use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Filter;
use Try::Tiny;

use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Types ':all';
use Gat::Error;

has 'asset_dir' => (
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

has 'digest_type' => (
    is      => 'ro',
    isa     => Str,
    default => 'MD5',
);

sub BUILD {
    my ($self) = @_;
    croak "Repository->asset_dir does not exist!" unless -d $self->asset_dir;
}

sub compute_checksum {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $digest = Digest->new($self->digest_type);

    try {
        my $fh     = $file->openr;
        $digest->addfile($fh);
    }
    catch {
        Gat::Error->throw(message => "unable to compute checksum of $file");
    };

    return $digest->hexdigest;
}

sub resolve {
    my ($self, $checksum) = @_;
    my $prefix = substr($checksum, 0, 2);

    return $self->asset_dir->subdir($prefix)->file(substr($checksum, 2));
}

sub fetch {
    my ($self, $checksum) = @_;
    my $file = $self->resolve($checksum);
    
    if (-f $file) {
        return $file;
    }
    else {
        Gat::Error->throw( message => "missing asset $file" )  unless -f $file;
    }
}

sub insert {
    my $self = shift;
    my ($file) = pos_validated_list(
        \@_,
        { isa => AbsoluteFile, coerce => 1 },
    );

    my $info = lstat($file);
    Gat::Error->throw(message => "$file does not exist")        unless -e _;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;
    Gat::Error->throw(message => "$file is a symlink")          if     -l _;

    my $checksum   = $self->compute_checksum($file);
    my $asset_file = $self->resolve($checksum);

    $asset_file->parent->mkpath;       # ensure path exists
    move_reliable($file, $asset_file); # move the file over.
    chmod('a-w', $asset_file);         # remove write perms.

    $self->attach($file, $checksum);
    return wantarray ? ($checksum, $info) : $checksum;
}

sub attach {
    my $self = shift;
    my ($file, $checksum) = pos_validated_list(
        \@_,
        { isa => AbsoluteFile, coerce => 1 },
        { isa => Checksum },
    );

    Gat::Error->throw( message => "Can't overwrite $file" ) if -e $file;

    my $asset_file = $self->fetch($checksum);
    $file->parent->mkpath;

    if ($self->use_symlinks) {
        symlink( $asset_file->relative($file->parent), $file );
    }
    else {
        link( $asset_file, $file);
    }
}

sub remove {
    my $self = shift;
    my ($checksum) = pos_validated_list(
        \@_,
        { isa => Checksum },
    );

    my $asset_file = $self->resolve($checksum);

    unlink($asset_file) if -f $asset_file;
}

sub verify {
    my $self = shift;
    my ($file, $checksum) = pos_validated_list(
        \@_,
        { isa => AbsoluteFile, coerce => 1 },
        { isa => Checksum },
    );

    return undef unless -f $file;
    return undef unless -f $self->resolve($checksum);
    return 0 if $self->compute_checksum($file) ne $checksum;
    return 1;
}

sub assets {
    my ($self) = @_;

    return Data::Stream::Bulk::Filter->new(
        filter => sub { [ map { basename(dirname("$_")) . basename("$_") } @$_ ] },
        stream => Data::Stream::Bulk::Path::Class->new(
            dir        => $self->asset_dir,
            only_files => 1,
        ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

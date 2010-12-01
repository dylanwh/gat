package Gat::Repository;

# ABSTRACT: The (default) asset method (store files in $GAT_DIR/asset)

use Moose;
use namespace::autoclean;

use File::Copy::Reliable 'move_reliable';
use File::Basename;
use Digest;

use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Filter;

use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Types ':all';
use Gat::Error;

has 'digest_type' => (
    is      => 'ro',
    isa     => Str,
    default => 'MD5',
);

has 'asset_dir' => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

has 'use_symlinks' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

requires 'insert', 'link', 'remove', 'verify', 'assets';

sub compute_checksum {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $digest = Digest->new($self->digest_type);
    my $fh     = $file->openr;
    $digest->addfile($fh);
    return $digest->hexdigest;
}

sub _resolve {
    my ($self, $checksum) = @_;
    my $prefix = substr($checksum, 0, 2);

    return $self->asset_dir->subdir($prefix)->file(substr($checksum, 2));
}


sub fetch {
    my ($self, $checksum) = @_;
    my $file = $self->_resolve($checksum);
    
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

    Gat::Error->throw(message => "$file does not exist")        unless -e $file;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;

    my $checksum   = $self->compute_checksum($file);
    my $asset_file = $self->_resolve($checksum);

    if (-f $asset_file) { # already have that, so remove it.
        unlink($file);
    }
    else {                                   # don't have it
        $asset_file->parent->mkpath;         # ensure path exists
        move_reliable($file, $asset_file);   # move the file over.
    }

    $self->link($file, $checksum);
    return $checksum;
}

sub link {
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

    my $asset_file = $self->_resolve($checksum);

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
    return undef unless -f $self->_resolve_safe($checksum);
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

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

has 'format' => (
    is      => 'ro',
    isa     => Str,
    default => 'MD5',
);

sub BUILD {
    my ($self) = @_;
    croak "Repository->asset_dir does not exist!" unless -d $self->asset_dir;
}

sub _compute_checksum {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
    my $digest = Digest->new($self->format);

    try {
        my $fh = $file->openr;
        $digest->addfile($fh);
    }
    catch {
        Gat::Error->throw(message => "unable to compute checksum of $file");
    };

    return $digest->hexdigest;
}

sub _resolve {
    my ($self, $checksum) = @_;
    my $prefix = substr($checksum, 0, 2);

    return $self->asset_dir->subdir($prefix)->file(substr($checksum, 2));
}

sub _fetch {
    my ($self, $checksum) = @_;
    my $file = $self->_resolve($checksum);
    
    if (-f $file) {
        return $file;
    }
    else {
        Gat::Error->throw( message => "missing asset $file" )  unless -f $file;
    }
}

sub _is_attached {
    my $self = shift;
    my ($file, $checksum) = pos_validated_list(
        \@_,
        { isa => AbsoluteFile, coerce => 1 },
        { isa => Checksum },
    );

    if (-l $file) {
        my $asset_file = $self->_fetch($checksum)->relative( $file->parent );
        return readlink($file) eq $asset_file;
    }
    else {
        return $self->_compute_checksum($file) eq $checksum;
    }
}

sub insert {
    my $self = shift;
    my ($file) = validated_list(
        \@_,
        file => { isa => AbsoluteFile, coerce => 1 },
    );

    my $stat = lstat($file);
    Gat::Error->throw(message => "$file does not exist")        unless -e _;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;
    Gat::Error->throw(message => "$file is a symlink")          if     -l _;

    my $checksum   = $self->_compute_checksum($file);
    my $asset_file = $self->_resolve($checksum);

    $asset_file->parent->mkpath;       # ensure path exists
    move_reliable($file, $asset_file); # move the file over.
    chmod('a-w', $asset_file);         # remove write perms.

    return wantarray ? ($checksum, $stat) : $checksum;
}

sub move {
    my $self = shift;
    my ( $file, $checksum ) = validated_list(
        file     => { isa => AbsoluteFile, coerce => 1 },
        checksum => { isa => Checksum },
    );

    my $asset_file = $self->_fetch($checksum);
    move_reliable($asset_file, $file);
}

sub copy {
    my $self = shift;
    my ( $file, $checksum ) = validated_list(
        file     => { isa => AbsoluteFile, coerce => 1 },
        checksum => { isa => Checksum },
    );

    my $asset_file = $self->_fetch($checksum);
    copy_reliable($asset_file, $file);
}

# most called during GC
sub remove {
    my $self = shift;
    my ($checksum) = validated_list(
        \@_,
        checksum => { isa => Checksum },
    );

    my $asset_file = $self->_resolve($checksum);
    unlink($asset_file) if -f $asset_file;
}

sub attach {
    my $self = shift;
    my ( $file, $checksum, $symlink ) = validated_list(
        \@_,
        file     => { isa => AbsoluteFile, coerce  => 1 },
        checksum => { isa => Checksum },
        symlink  => { isa => Bool,         default => 1 },
    );

    Gat::Error->throw( message => "Can't overwrite $file" ) if -e $file;

    my $asset_file = $self->_fetch($checksum);
    $file->parent->mkpath;

    if ($symlink) {
        symlink( $asset_file->relative($file->parent), $file );
    }
    else {
        link( $asset_file, $file);
    }
}

sub detach {
    my $self = shift;
    my ( $file, $checksum ) = validated_list(
        \@_,
        file     => { isa => AbsoluteFile, coerce => 1 },
        checksum => { isa => Checksum },
    );

    unless (-e $file) {
        Gat::Error->throw(
            message => "Cannot detach $file because it does not exist.",
        );
    }

    if ($self->_is_attached($file, $checksum)) {
        unlink($file);
    }
    else {
        Gat::Error->throw(
            message => "Cannot detach $file because it is not attached to $checksum",
        );
    }
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

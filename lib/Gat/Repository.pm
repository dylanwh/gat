package Gat::Repository;

# ABSTRACT: The (default) asset method (store files in $GAT_DIR/asset)
use Moose;
use namespace::autoclean;
use strictures 1;

use File::Copy::Reliable 'move_reliable', 'copy_reliable';
use File::Basename;
use File::stat;
use File::chmod;
use Digest;
use Carp;

use autodie;

use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Filter;
use Try::Tiny;

use Moose::Util::TypeConstraints 'enum';
use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Types ':all';
use Gat::Error;

has 'config' => (
    is       => 'ro',
    isa      => 'Gat::Config',
    required => 1,
);

has 'path' => (
    is       => 'ro',
    isa      => 'Gat::Path',
    required => 1,
);

has 'asset_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    init_arg => undef,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_asset_dir',
);

has 'digest_type' => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_digest_type',
);

has 'attach_method' => (
    is       => 'ro',
    isa      => enum( [ 'link', 'symlink', 'copy' ] ),
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_attach_method',
);

sub _build_asset_dir {
    my $self = shift;

    $self->path->absolute(
        $self->config->get(key => 'repository.asset_dir') || '.gat/asset',
        $self->path->base_dir,
    );
}

sub _build_digest_type {
    my $self = shift;
    $self->config->get(key => 'repository.digest_type') || 'MD5';
}

sub _build_attach_method {
    my $self = shift;
    $self->config->get(key => 'repository.attach_method') || 'symlink';
}

sub BUILD {
    my ($self) = @_;
    croak "Repository->asset_dir does not exist!" unless -d $self->asset_dir;
}

sub _checksum {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
    my $digest = Digest->new($self->digest_type);

    try {
        my $fh = $file->openr;
        $digest->addfile($fh);
    }
    catch {
        Gat::Error->throw(message => "unable to compute checksum of $file");
    };

    return $digest->hexdigest;
}

sub _asset_file {
    my ($self, $checksum) = @_;
    my $prefix = substr($checksum, 0, 2);

    return $self->asset_dir->subdir($prefix)->file(substr($checksum, 2));
}

sub _is_attached {
    my $self = shift;
    my ($file, $checksum) = pos_validated_list(
        \@_,
        { isa => AbsoluteFile, coerce => 1 },
        { isa => Checksum },
    );

    if (-l $file) {
        my $asset_file = $self->_asset_file($checksum)->relative( $file->parent );
        return readlink($file) eq $asset_file;
    }
    # FIXME: if on same fs, check inode number (if possible)
    elsif (-f _) {
        return $self->_checksum($file) eq $checksum;
    }
    else {
        return undef;
    }
}

sub store {
    my $self = shift;
    my ($file, $preserve) = validated_list(
        \@_,
        file     => { isa => AbsoluteFile, coerce  => 1 },
        preserve => { isa => Bool,         default => 0 },
    );

    my $stat = lstat($file);
    Gat::Error->throw(message => "$file does not exist")        unless -e _;
    Gat::Error->throw(message => "$file is not a regular file") unless -f _;
    Gat::Error->throw(message => "$file is a symlink")          if     -l _;

    my $checksum   = $self->_checksum($file);          # calculate checksum.
    my $asset_file = $self->_asset_file($checksum);    # figure out path in asset dir.
    $asset_file->parent->mkpath;                       # ensure path exists
    if ($preserve) {
        copy_reliable( $file, $asset_file );           # copy the file (preserve original)
    }
    else {
        move_reliable( $file, $asset_file );           # move the file over (destroy original)
    }
    chmod( 'a-w', $asset_file );                       # remove write perms.

    return wantarray ? ( $checksum, $stat ) : $checksum;
}

# most called during GC
# this is a no-op if the assetfile does not exist.
sub remove {
    my $self = shift;
    my ($checksum) = validated_list(\@_,
        checksum => { isa => Checksum },
    );

    my $asset_file = $self->_asset_file($checksum);
    unlink($asset_file) if -f $asset_file;
}

sub attach {
    my $self = shift;
    my ( $file, $checksum, $method ) = validated_list(\@_,
        file     => { isa => AbsoluteFile, coerce  => 1 },
        checksum => { isa => Checksum },
    );

    unless ($self->_is_attached($file, $checksum)) {
        my $asset_file = $self->_asset_file($checksum);
        $file->parent->mkpath;

        Gat::Error->throw( message => "Can't overwrite $file" ) if -e $file;
        Gat::Error->throw( message => "Missing asset for $checksum" ) unless -f $asset_file;

        my $attach_method = "_attach_" . $self->attach_method;
        $self->$attach_method($asset_file, $file);
    }
}

sub _attach_link {
    my ( $self, $asset_file, $file ) = @_;
    link( $asset_file, $file );
}

sub _attach_symlink {
    my ( $self, $asset_file, $file ) = @_;
    symlink( $asset_file->relative( $file->parent ), $file );
}

sub _attach_copy {
    my ( $self, $asset_file, $file ) = @_;
    copy_reliable( $asset_file, $file );
}


sub detach {
    my $self = shift;
    my ( $file, $checksum ) = validated_list(\@_,
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

sub checksums {
    my ($self) = @_;

    return Data::Stream::Bulk::Filter->new(
        filter => sub { [ map { basename($_->parent) . $_->basename } @$_ ] },
        stream => Data::Stream::Bulk::Path::Class->new(
            dir        => $self->asset_dir,
            only_files => 1,
        ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

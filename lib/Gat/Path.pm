package Gat::Path;
use Moose;
use namespace::autoclean;

use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';

use Gat::Types ':all';
use Gat::Constants 'GAT_HASH';

use Digest;
use Fcntl ':mode';
use File::Spec;
use File::stat;
use File::chmod ();
use File::Copy::Reliable 'move_reliable', 'copy_reliable';
use Path::Class;

has 'filename' => (
    is          => 'ro',
    isa         => AbsoluteFile,
    coerce      => 1,
    required    => 1,
    initializer => '_init_filename',
    handles     => [qw[ openr touch stringify ]],
);

has 'fileinfo' => (
    is         => 'rw',
    isa        => 'Maybe[File::stat]',
    lazy_build => 1,
    handles    => {
        mode   => 'mode',
        size   => 'size',
        mtime  => 'mtime',
        device => 'dev',
        inode  => 'ino',
    },
    predicate => 'has_fileinfo',
);

has 'checksum' => (
    is         => 'rw',
    isa        => Maybe[Checksum],
    lazy_build => 1,
    predicate => 'has_checksum',
);

sub exists {
    my $self = shift;

    return defined $self->fileinfo;
}

sub is_link {
    my $self = shift;

    return S_ISLNK($self->mode);
}

sub is_file {
    my $self = shift;

    return S_ISREG($self->mode);
}

sub is_dir {
    my $self = shift;

    return S_ISDIR($self->mode);
}

after 'copy', 'link' => sub {
    my ($self, $dest) = @_;

    $dest->fileinfo( $self->fileinfo ) if $self->has_fileinfo;
    $dest->checksum( $self->checksum ) if $self->has_checksum;
};

after 'move' => sub {
    my ($self, $dest) = @_;

    $dest->fileinfo( $self->fileinfo ) if $self->has_fileinfo;
    $dest->checksum( $self->checksum ) if $self->has_checksum;

    $self->clear_cache;
};

after 'unlink', 'chmod', 'touch' => sub {
    my ($self) = @_;
    
    $self->clear_cache;
};

before 'touch' => sub {
    my ($self) = @_;
    $self->filename->parent->mkpath;
};

before 'copy', 'link', 'move', 'symlink' => sub {
    my ($self, $other) = @_;
    if ($self->exists) {
        $other->filename->parent->mkpath;
    }
};

sub clear_cache {
    my $self = shift;

    $self->clear_checksum;
    $self->clear_fileinfo;
}

sub move {
    my $self = shift;
    my ($dest) = pos_validated_list(\@_, { isa => Path });

    move_reliable($self->filename, $dest->filename);
}

sub copy {
    my $self = shift;
    my ($dest) = pos_validated_list(\@_, { isa => Path });

    copy_reliable($self->filename, $dest->filename);
}

sub symlink {
    my $self = shift;
    my ($dest) = pos_validated_list(\@_, { isa => Path });

    CORE::symlink($self->filename->relative( $dest->filename->parent ), $dest->filename)
        or die "$!";
}

sub link {
    my $self = shift;
    my ($dest) = pos_validated_list(\@_, { isa => Path });

    CORE::link($self->filename, $dest->filename)
        or die "$!";
}

sub unlink {
    my $self = shift;

    CORE::unlink($self->filename)
        or die "$!";
}

sub readlink {
    my $self = shift;

    if ($self->exists && $self->is_link) {
        return file(CORE::readlink($self->filename));
    }
    else {
        return undef;
    }
}

sub target {
    my $self = shift;

    if (my $target = $self->readlink) {
        return Gat::Path->new(
            filename => $target->absolute( $self->filename->parent ),
        );
    }
    else {
        return undef;
    }
}

sub chmod {
    my $self = shift;
    my ($mode) = pos_validated_list(\@_, { isa => Int|Str });

    File::chmod::chmod($mode, $self->filename);
}

sub _build_checksum {
    my ($self) = @_;

    if ($self->exists && $self->is_file) {
        my $digest = Digest->new(GAT_HASH);
        my $fh     = $self->openr;
        $digest->addfile($fh);

        return $digest->hexdigest;
    }
    else {
        return undef;
    }
}

sub _build_fileinfo {
    my ($self) = @_;
    lstat($self->filename);
}

sub _init_filename {
    my ( $self, $file, $set, $attr ) = @_;

    my @dirs;
    for my $dir ( File::Spec->splitdir( $file->stringify ) ) {
        if ( $dir eq '..' ) {
            pop @dirs if @dirs;
        }
        else {
            push @dirs, $dir;
        }
    }

    return $set->( Path::Class::File->new(@dirs) );
}

__PACKAGE__->meta->make_immutable;
1;

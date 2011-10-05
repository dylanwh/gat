package Gat::Path;
use Moose;
#use namespace::autoclean; damn overload

use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File', 'Dir';

use Carp;
use Digest;
use Fcntl ':mode';
use File::Copy::Reliable 'move_reliable', 'copy_reliable';
use File::chmod ();
use Path::Class 'file';

use Gat::Types ':all';
use Gat::Util 'cleanup_filename';

use namespace::clean;

use overload (
    q{""}    => 'stringify',
    fallback => 1,
);

with 'MooseX::OneArgNew' => { type => AbsoluteFile | Str, init_arg => 'filename' },
     'MooseX::Clone';

has 'filename' => (
    is       => 'ro',
    isa      => AbsoluteFile,
    coerce   => 1,
    required => 1,
    initializer => '_init_filename',
    handles  => [qw[ slurp touch stringify ]],
);

#has 'stat' => (
#    traits  => ['NoClone'],
#    is      => 'ro',
#    isa     => Maybe[FileStat],
#    builder => '_build_stat',
#    lazy    => 1,
#);

sub stat   { return scalar $_[0]->filename->lstat; }
sub exists { return -e $_[0]->filename }

sub digest {
    my $self = shift;
    my ($digest_type) = pos_validated_list(\@_, { isa => Str });

    my $digest = Digest->new($digest_type);
    my $fh     = $self->filename->openr;
    $digest->addfile($fh);

    return $digest->hexdigest;
}

before 'touch' => sub {
    my ($self) = @_;

    $self->mkpath;
};

before 'copy', 'link', 'move', 'symlink' => sub {
    my ( $self, $dest ) = @_;

    $dest->mkpath if $self->stat;
};

sub to_label {
    my $self = shift;
    my ($base_dir) = pos_validated_list(\@_, { isa => AbsoluteDir });

    return Gat::Label->new( $self->filename->relative( $base_dir ));
}

sub mkpath {
    my $self = shift;

    $self->filename->parent->mkpath(@_);
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
        or confess "$!: ". $dest->filename;
}

sub link {
    my $self = shift;
    my ($dest) = pos_validated_list(\@_, { isa => Path });

    CORE::link($self->filename, $dest->filename)
        or confess "$!";
}

sub unlink {
    my $self = shift;

    CORE::unlink($self->filename)
        or confess "$!";
}

sub readlink {
    my $self = shift;

    my $s = CORE::readlink($self->filename);
    if (defined $s) {
        return Gat::Path->new(filename => file($s)->absolute( $self->filename->parent ));
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

sub _init_filename {
    my ( $self, $file, $set, $attr ) = @_;
    
    $set->( cleanup_filename($file) );
}

__PACKAGE__->meta->make_immutable;
1;

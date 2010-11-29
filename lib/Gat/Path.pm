package Gat::Path;
use Moose;
use namespace::autoclean;

use Carp;
use Path::Class 'dir';
use List::MoreUtils 'first_value';

use MooseX::Params::Validate;
use MooseX::Types::Path::Class ':all';

use Gat::Path::Rules;
use Gat::Types ':all';

has 'rules' => (
    is         => 'ro',
    isa        => 'Gat::Path::Rules',
    lazy_build => 1,
);

has 'work_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_work_dir',
    handles => { work_file => 'file' },
);

has 'base_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    lazy    => 1,
    builder => '_build_base_dir',
    handles => { base_file => 'file' },
);

has 'gat_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    builder => '_build_gat_dir',
    lazy    => 1,
    handles => {
        'gat_file'   => 'file',
        'gat_subdir' => 'subdir',
    },
);

has 'gat_dir_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => '.gat',
);


sub _build_work_dir { dir('.')->absolute }

sub _build_base_dir {
    my ($self) = @_;

    my $root = dir('');
    my $base = $self->work_dir;

    until ($base eq $root || -d $base->subdir($self->gat_dir_name)) {
        $base = $base->parent;
    }
    
    return $self->work_dir if $base eq $root;
    return $base;
}

sub _build_gat_dir {
    my ($self) = @_;

    return $self->base_dir->subdir($self->gat_dir_name);

}

sub _build_rules {
    my ($self) = @_;
    my $file = $self->gat_file('rules.yml');

    if (-f $file) {
        return Gat::Path::Rules->load($file);
    }
    else {
        return Gat::Path::Rules->new;
    }
}

sub save_rules {
    my ($self) = @_;
    my $file = $self->gat_file('rules.yml');

    $self->rules->store( $file );
}

sub cleanup {
    my $self = shift;
    my ($file) = pos_validated_list( \@_, { isa => File, coerce => 1 } );

    my @dirs;
    for my $dir ( File::Spec->splitdir($file->stringify) ) {
        if ( $dir eq '..' ) {
            pop @dirs if @dirs;
        }
        else {
            push @dirs, $dir;
        }
    }

    return Path::Class::File->new(File::Spec->catdir(@dirs));
}


sub relative {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
   
    return $self->absolute($file)->relative( $self->work_dir );
}

sub absolute {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    return $self->cleanup( $file->absolute( $self->work_dir ) );
}

sub canonical {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    return $self->absolute($file)->relative( $self->base_dir );
}

sub is_valid {
    my $self     = shift;
    my ($file)   = pos_validated_list( \@_, { isa => File, coerce => 1 } );
    my $abs_file = $self->absolute($file);

    return $self->base_dir->subsumes($abs_file) && !$self->gat_dir->subsumes($abs_file);
}

sub is_allowed {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
    my $cfile  = $self->canonical( $file );

    my $pred   = first_value { $cfile =~ $_->[0] } $self->rules->predicates;
    return $pred ? $pred->[1] : $self->rules->default;
}

__PACKAGE__->meta->make_immutable;

1;

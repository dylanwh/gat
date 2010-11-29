package Gat::Path;
use Moose;
use namespace::autoclean;

use Carp;
use Path::Class 'dir';
use List::MoreUtils 'first_value';

use MooseX::Params::Validate;
use MooseX::Types::Moose ':all';
use MooseX::Types::Structured 'Tuple';
use MooseX::Types::Path::Class ':all';

use Gat::Types ':all';
use Gat::Path::File;

has 'rules' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [RegexpRef, Bool] ],
    reader  => '_rules',
    handles => { 'rules' => 'elements' },
    default => sub { [] },
);

has 'rule_default' => (
    is       => 'ro',
    isa      => Bool,
    default  => 1,
);

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    builder  => '_build_work_dir',
    lazy     => 1,
);

has 'base_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    builder => '_build_base_dir',
    lazy    => 1,
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

sub relative {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
   
    return $self->absolute($file)->relative( $self->work_dir );
}

sub absolute {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    return $file->absolute( $self->work_dir );
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

    my $rule   = first_value { $cfile =~ $_->[0] } $self->rules;
    return $rule ? $rule->[1] : $self->rule_default;
}

__PACKAGE__->meta->make_immutable;
1;


__PACKAGE__->meta->make_immutable;

1;

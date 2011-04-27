package Gat::Context;
use Moose;
use namespace::autoclean;

use MooseX::Params::Validate;
use MooseX::Types::Path::Class ':all';
use Cwd;
use Path::Class;
use Gat::Rules;

use constant GAT_DIR => '.gat';

has 'rules' => (
    reader   => '_rules',
    isa      => 'Gat::Rules',
    handles  => {
        is_allowed => 'is_allowed',
        _loaded_rules  => 'has_predicates',
        _load_rules    => 'load_rules',
    },
    lazy_build => 1,
);

has 'work_dir' => (
    is         => 'ro',
    isa        => Dir,
    coerce     => 1,
    lazy_build => 1,
);

has 'base_dir' => (
    is         => 'ro',
    isa        => Dir,
    coerce     => 1,
    lazy_build => 1,
);

has 'gat_dir' => (
    is         => 'ro',
    isa        => Dir,
    coerce     => 1,
    lazy_build => 1,
);

before 'is_allowed' => sub {
    my ($self) = @_;
    $self->_load_rules( $self->gat_dir->file('rules') ) unless $self->_loaded_rules;
};

sub _build_rules { Gat::Rules->new }

sub _build_work_dir { cwd }

sub _build_gat_dir { $_[0]->base_dir->subdir(GAT_DIR) }

sub _build_base_dir {
    my ($self) = @_;
    my $work = $self->work_dir;
    my $root = dir('');
    my $base = $work;

    until (-d $base->subdir(GAT_DIR)) {
        $base = $base->parent;
        return $work if $base eq $root;
    }

    return $base;
}

sub path {
    my $self = shift;
    my ($file) = pos_validated_list( \@_,
        { isa => File, coerce => 1 },
    );
    if ($file->is_relative) {
        Gat::Path->new( $file->absolute( $self->work_dir ) );
    }
    else {
        Gat::Path->new($file);
    }
}

sub label {
    my $self = shift;
    my ($file) = pos_validated_list( \@_,
        { isa => File, coerce => 1 },
    );
    if ($file->is_relative) {
        Gat::Label->new($file);
    }
    else {
        Gat::Label->new( $file->relative( $self->base_dir ) );
    }
}

__PACKAGE__->meta->make_immutable;
1;

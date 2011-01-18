package Gat::Path;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File';
use MooseX::Params::Validate;
use Gat::Types ':all';

has 'rules' => (
    is       => 'ro',
    isa      => 'Gat::Rules',
    handles  => { '_is_allowed' => 'is_allowed' },
);

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

has 'gat_dir' => (
    is         => 'ro',
    isa        => AbsoluteDir,
    coerce     => 1,
    lazy_build => 1,
);

has 'filter' => (
    is         => 'ro',
    isa        => 'CodeRef',
    lazy_build => 1,
);

sub _build_gat_dir { $_[0]->base_dir->subdir('.gat') }

sub _build_filter {
    my $self = shift;
    return sub { 
        [ 
            grep { $self->is_valid($_) && $self->_is_allowed( $self->canonical( $_ ) ) } @$_
        ]
    };
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
    my $self = shift;
    my ($file)   = pos_validated_list( \@_, { isa => File, coerce => 1 } );

    return $self->_is_allowed( $self->canonical( $file ) );
}

__PACKAGE__->meta->make_immutable;
1;

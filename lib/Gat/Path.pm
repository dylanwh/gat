package Gat::Path;
use Moose;
use namespace::autoclean;

use Carp;
use Path::Class 'dir';

use MooseX::Params::Validate;
use MooseX::Types::Path::Class ':all';

use Gat::Types ':all';

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
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

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
    if ($self->has_rules) {
        return $self->rules->is_allowed( $self->canonical( $file ) );
    }
    else {
        return 1;
    }
}

__PACKAGE__->meta->make_immutable;

1;
